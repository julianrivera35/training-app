import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import '../models/exercise.dart';
import '../models/load_exercise.dart';
import '../models/progress_entry.dart';
import '../models/shopping_item.dart';
import '../services/excel_parser.dart';
import '../services/data_service.dart';

enum ImportStatus { idle, loading, success, error }

class AppProvider extends ChangeNotifier {
  List<TrainingDay> _days = [];
  List<LoadExercise> _loadExercises = [];
  List<double> _weekPercents = [];
  Map<String, double> _rms = {};
  Map<int, Set<String>> _completedByWeek = {};
  List<ShoppingItem> _shopping = [];
  List<ProgressEntry> _progress = [];
  DateTime? _startDate; // lunes de la semana 1
  String? _lastImport;
  ImportStatus importStatus = ImportStatus.idle;
  String? importError;
  int _tabIndex = 0;

  List<TrainingDay>    get days      => _days;
  List<LoadExercise>   get loadExercises => _loadExercises;
  List<double>         get weekPercents  => _weekPercents;
  Map<String, double>  get rms       => _rms;
  List<ShoppingItem>   get shopping  => _shopping;
  List<ProgressEntry>  get progress  => List.unmodifiable(_progress);
  DateTime?            get startDate => _startDate;
  String?              get lastImport => _lastImport;
  int get tabIndex                   => _tabIndex;
  bool get hasPlan => _days.isNotEmpty;

  Future<void> init() async {
    _startDate   = await DataService.getStartDate();
    _lastImport  = await DataService.getLastImport();
    _days        = await DataService.loadPlan();
    final cargas = await DataService.loadCargas();
    _loadExercises = cargas.$1;
    _weekPercents  = cargas.$2;
    _rms         = await DataService.loadRms();
    _completedByWeek = await DataService.loadCompleted();
    _shopping    = await DataService.loadShopping();
    _progress    = await DataService.loadProgress();
    notifyListeners();
  }

  void setTab(int i) { _tabIndex = i; notifyListeners(); }

  // ── Semana / fecha ─────────────────────────────────────────────
  static DateTime _mondayOf(DateTime d) {
    final day = DateTime(d.year, d.month, d.day);
    return day.subtract(Duration(days: day.weekday - 1)); // lunes = 1
  }

  int get currentWeek {
    if (_startDate == null) return 1;
    final diff = _mondayOf(DateTime.now()).difference(_startDate!).inDays;
    return (diff ~/ 7) + 1 < 1 ? 1 : (diff ~/ 7) + 1;
  }

  int get blockWeek {
    if (_weekPercents.isEmpty) return 1;
    return ((currentWeek - 1) % _weekPercents.length) + 1;
  }

  double? get currentPercent =>
      _weekPercents.isEmpty ? null : _weekPercents[blockWeek - 1];

  String get currentPhase {
    final b = blockWeek;
    if (b <= 2) return 'Acumulación';
    if (b <= 4) return 'Intensificación';
    if (b <= 6) return 'Pico de fuerza';
    if (b == 7) return 'Peak';
    return 'Taper 🔽';
  }

  Future<void> setStartDate(DateTime d) async {
    _startDate = _mondayOf(d);
    await DataService.setStartDate(_startDate!);
    notifyListeners();
  }

  // ── Hoy ────────────────────────────────────────────────────────
  String get todayDayName {
    const map = {1:'LUNES',2:'MARTES',3:'MIÉRCOLES',4:'JUEVES',5:'VIERNES',6:'SÁBADO',7:'DOMINGO'};
    return map[DateTime.now().weekday] ?? 'LUNES';
  }

  TrainingDay? get todayTraining {
    final today = _noAccents(todayDayName);
    try {
      return _days.firstWhere((d) => _noAccents(d.name.toUpperCase()).startsWith(today));
    } catch (_) { return null; }
  }

  // ── Cargas: plan = 1RM × % de la semana ───────────────────────
  double? rmFor(String nombre) {
    final n = _normalize(nombre);
    for (final e in _rms.entries) {
      final k = _normalize(e.key);
      if (k == n || k.contains(n) || n.contains(k)) return e.value;
    }
    return null;
  }

  Future<void> setRM(String nombre, double? kg) async {
    if (kg == null || kg <= 0) {
      _rms.remove(nombre);
    } else {
      _rms[nombre] = kg;
    }
    notifyListeners();
    await DataService.saveRms(_rms);
  }

  double? plannedWeightFor(String nombre) {
    final rm = rmFor(nombre);
    final pct = currentPercent;
    if (rm == null || pct == null) return null;
    final raw = rm * pct / 100;
    return (raw / 2.5).round() * 2.5; // redondeo a 2.5 kg
  }

  String _normalize(String s) => s.toLowerCase()
      .replaceAll('á','a').replaceAll('é','e').replaceAll('í','i')
      .replaceAll('ó','o').replaceAll('ú','u').replaceAll('ñ','n').trim();
  String _noAccents(String s) => s
      .replaceAll('Á','A').replaceAll('É','E').replaceAll('Í','I')
      .replaceAll('Ó','O').replaceAll('Ú','U');

  // ── Completitud por semana ────────────────────────────────────
  String _key(String day, String ejercicio) => '$day|$ejercicio';

  bool isDone(String day, String ejercicio) =>
      _completedByWeek[currentWeek]?.contains(_key(day, ejercicio)) ?? false;

  Future<void> toggleDone(String day, String ejercicio) async {
    final set = _completedByWeek.putIfAbsent(currentWeek, () => <String>{});
    final k = _key(day, ejercicio);
    if (!set.remove(k)) set.add(k);
    notifyListeners();
    await DataService.saveCompleted(_completedByWeek);
  }

  int completedCount(String dayName) {
    final day = _days.where((d) => d.name == dayName).firstOrNull;
    if (day == null) return 0;
    return day.exercises.where((e) => isDone(dayName, e.nombre)).length;
  }

  /// Entrenos (ejercicios completados) por número de semana — para adherencia.
  Map<int, int> get completedPerWeek =>
      {for (final e in _completedByWeek.entries) e.key: e.value.length};

  // ── Import Excel ───────────────────────────────────────────────
  Future<void> importExcel() async {
    importStatus = ImportStatus.loading;
    importError = null;
    notifyListeners();

    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.any, withData: true);
      if (result == null || result.files.isEmpty) {
        importStatus = ImportStatus.idle;
        notifyListeners();
        return;
      }
      final picked = result.files.first;
      final bytes = picked.bytes;
      if (bytes == null) throw Exception('No se pudo leer el archivo');
      final name = picked.name.toLowerCase();
      final looksXlsx = name.endsWith('.xlsx') ||
          (bytes.length > 1 && bytes[0] == 0x50 && bytes[1] == 0x4B);
      if (!looksXlsx) throw Exception('Selecciona un archivo Excel (.xlsx)');

      final plan = ExcelParser.parse(bytes);
      _days = plan.days;
      _loadExercises = plan.loadExercises;
      _weekPercents = plan.weekPercents;

      // Conserva marcas de comprado del mercado por nombre.
      final compradoPrev = {for (final s in _shopping) s.nombre: s.comprado};
      _shopping = plan.shopping;
      for (final s in _shopping) {
        s.comprado = compradoPrev[s.nombre] ?? s.comprado;
      }

      // Semana 1 = primer entreno (si no estaba fijada).
      _startDate ??= _mondayOf(DateTime.now());
      _lastImport = DateTime.now().toIso8601String();

      await DataService.savePlan(_days);
      await DataService.saveCargas(_loadExercises, _weekPercents);
      await DataService.saveShopping(_shopping);
      await DataService.setStartDate(_startDate!);
      await DataService.setLastImport(_lastImport!);

      importStatus = ImportStatus.success;
    } catch (e) {
      importStatus = ImportStatus.error;
      importError = e.toString();
    }
    notifyListeners();
  }

  // ── Progress ───────────────────────────────────────────────────
  Future<void> addProgress(ProgressEntry entry) async {
    _progress.removeWhere((e) =>
      e.fecha.year == entry.fecha.year &&
      e.fecha.month == entry.fecha.month &&
      e.fecha.day == entry.fecha.day);
    _progress.insert(0, entry);
    _progress.sort((a, b) => b.fecha.compareTo(a.fecha));
    await DataService.saveProgress(_progress);
    notifyListeners();
  }

  Future<void> deleteProgress(int index) async {
    if (index < 0 || index >= _progress.length) return;
    _progress.removeAt(index);
    await DataService.saveProgress(_progress);
    notifyListeners();
  }

  // ── Shopping ───────────────────────────────────────────────────
  Future<void> toggleShopping(ShoppingItem item) async {
    item.comprado = !item.comprado;
    notifyListeners();
    await DataService.saveShopping(_shopping);
  }

  Future<void> resetShopping() async {
    for (final s in _shopping) { s.comprado = false; }
    notifyListeners();
    await DataService.saveShopping(_shopping);
  }
}

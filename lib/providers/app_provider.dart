import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import '../models/exercise.dart';
import '../models/weekly_load.dart';
import '../models/nutrition_plan.dart';
import '../models/progress_entry.dart';
import '../models/shopping_item.dart';
import '../services/excel_parser.dart';
import '../services/data_service.dart';

enum ImportStatus { idle, loading, success, error }

class AppProvider extends ChangeNotifier {
  List<TrainingDay> _days = [];
  List<WeeklyLoad>  _loads = [];
  NutritionPlan     _nutrition = NutritionPlan.defaultPlan();
  List<ShoppingItem> _shopping = [];
  List<ProgressEntry> _progress = [];
  int _currentWeek = 1;
  String? _lastImport;
  ImportStatus importStatus = ImportStatus.idle;
  String? importError;
  int _tabIndex = 0;

  List<TrainingDay>   get days      => _days;
  List<WeeklyLoad>    get loads     => _loads;
  NutritionPlan       get nutrition => _nutrition;
  List<ShoppingItem>  get shopping  => _shopping;
  List<ProgressEntry> get progress  => List.unmodifiable(_progress);
  int get currentWeek               => _currentWeek;
  String? get lastImport            => _lastImport;
  int get tabIndex                  => _tabIndex;

  bool get hasPlan => _days.isNotEmpty;

  Future<void> init() async {
    _currentWeek = await DataService.getCurrentWeek();
    _lastImport  = await DataService.getLastImport();
    _days        = await DataService.loadPlan();
    _loads       = await DataService.loadLoads();
    _nutrition   = await DataService.loadNutrition();
    _shopping    = await DataService.loadShopping();
    _progress    = await DataService.loadProgress();
    notifyListeners();
  }

  // ── Tab navigation ─────────────────────────────────────────────
  void setTab(int i) { _tabIndex = i; notifyListeners(); }

  // ── Week ───────────────────────────────────────────────────────
  Future<void> setWeek(int w) async {
    _currentWeek = w.clamp(1, 8);
    await DataService.setCurrentWeek(_currentWeek);
    notifyListeners();
  }

  // ── Today helpers ──────────────────────────────────────────────
  String get todayDayName {
    const map = {1:'LUNES',2:'MARTES',3:'MIÉRCOLES',4:'JUEVES',5:'VIERNES',6:'SÁBADO',7:'DOMINGO'};
    return map[DateTime.now().weekday] ?? 'LUNES';
  }

  TrainingDay? get todayTraining {
    final today = todayDayName;
    try {
      return _days.firstWhere(
        (d) => d.name.toUpperCase().contains(today),
      );
    } catch (_) { return null; }
  }

  String get currentPhase {
    const phases = [
      'Acumulación I', 'Acumulación I', 'Acumulación II',
      'Intensificación I', 'Intensificación II', 'Pico de Fuerza',
      'Taper 🔽', 'Clasificatorios 🏆',
    ];
    final idx = (_currentWeek - 1).clamp(0, phases.length - 1);
    return phases[idx];
  }

  // ── Load lookup ────────────────────────────────────────────────
  WeeklyLoad? loadForExercise(String nombre) {
    try {
      return _loads.firstWhere(
        (l) => _normalize(l.nombre).contains(_normalize(nombre)) ||
               _normalize(nombre).contains(_normalize(l.nombre)),
      );
    } catch (_) { return null; }
  }

  String _normalize(String s) => s.toLowerCase()
      .replaceAll('á','a').replaceAll('é','e').replaceAll('í','i')
      .replaceAll('ó','o').replaceAll('ú','u').replaceAll('ñ','n');

  double? plannedWeightFor(String nombre) =>
      loadForExercise(nombre)?.planForWeek(_currentWeek);

  // ── Import Excel ───────────────────────────────────────────────
  Future<void> importExcel() async {
    importStatus = ImportStatus.loading;
    importError = null;
    notifyListeners();

    try {
      // FileType.any evita que iOS bloquee archivos por nombre/extensión
      // (p. ej. "PIVOTES_FINAL (1).xlsx"). Validamos por contenido al parsear.
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        withData: true,
      );
      if (result == null || result.files.isEmpty) {
        importStatus = ImportStatus.idle;
        notifyListeners();
        return;
      }

      final picked = result.files.first;
      final bytes = picked.bytes;
      if (bytes == null) throw Exception('No se pudo leer el archivo');

      final name = picked.name.toLowerCase();
      // Un .xlsx es un ZIP: empieza con "PK". Si no, avisamos claro.
      final looksXlsx = name.endsWith('.xlsx') ||
          (bytes.length > 1 && bytes[0] == 0x50 && bytes[1] == 0x4B);
      if (!looksXlsx) {
        throw Exception('Selecciona un archivo Excel (.xlsx)');
      }

      final plan = ExcelParser.parse(bytes);

      _days      = plan.days;
      _loads     = plan.loads;
      _nutrition = plan.nutrition;

      // Preserve "comprado" marks across re-imports, matched by item name.
      final compradoPrev = {for (final s in _shopping) s.nombre: s.comprado};
      _shopping = plan.shopping;
      for (final s in _shopping) {
        s.comprado = compradoPrev[s.nombre] ?? s.comprado;
      }

      _lastImport = DateTime.now().toIso8601String();

      await DataService.savePlan(_days);
      await DataService.saveLoads(_loads);
      await DataService.saveNutrition(_nutrition);
      await DataService.saveShopping(_shopping);
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
    // Replace if same day exists
    _progress.removeWhere((e) =>
      e.fecha.year == entry.fecha.year &&
      e.fecha.month == entry.fecha.month &&
      e.fecha.day == entry.fecha.day,
    );
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

  // ── Exercise completion (persisted) ───────────────────────────
  Future<void> toggleExercise(String dayName, String ejercicio) async {
    final day = _days.where((d) => d.name == dayName).firstOrNull;
    if (day == null) return;
    final ex = day.exercises.where((e) => e.nombre == ejercicio).firstOrNull;
    if (ex == null) return;
    ex.hecho = !ex.hecho;
    notifyListeners();
    await DataService.savePlan(_days);
  }

  Future<void> setExerciseRealWeight(String dayName, String ejercicio, double? kg) async {
    final day = _days.where((d) => d.name == dayName).firstOrNull;
    if (day == null) return;
    final ex = day.exercises.where((e) => e.nombre == ejercicio).firstOrNull;
    if (ex == null) return;
    ex.pesoReal = kg;
    notifyListeners();
    await DataService.savePlan(_days);
  }

  int completedCount(String dayName) {
    final day = _days.where((d) => d.name == dayName).firstOrNull;
    return day?.exercises.where((e) => e.hecho).length ?? 0;
  }

  // ── Shopping list ──────────────────────────────────────────────
  Future<void> toggleShopping(ShoppingItem item) async {
    item.comprado = !item.comprado;
    notifyListeners();
    await DataService.saveShopping(_shopping);
  }

  Future<void> resetShopping() async {
    for (final s in _shopping) {
      s.comprado = false;
    }
    notifyListeners();
    await DataService.saveShopping(_shopping);
  }
}

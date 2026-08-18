import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import '../models/exercise.dart';
import '../models/weekly_load.dart';
import '../models/nutrition_plan.dart';
import '../models/progress_entry.dart';
import '../services/excel_parser.dart';
import '../services/data_service.dart';

enum ImportStatus { idle, loading, success, error }

class AppProvider extends ChangeNotifier {
  List<TrainingDay> _days = [];
  List<WeeklyLoad>  _loads = [];
  NutritionPlan     _nutrition = NutritionPlan.defaultPlan();
  List<ProgressEntry> _progress = [];
  int _currentWeek = 1;
  String? _lastImport;
  ImportStatus importStatus = ImportStatus.idle;
  String? importError;
  int _tabIndex = 0;

  List<TrainingDay>   get days      => _days;
  List<WeeklyLoad>    get loads     => _loads;
  NutritionPlan       get nutrition => _nutrition;
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
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) {
        importStatus = ImportStatus.idle;
        notifyListeners();
        return;
      }

      final bytes = result.files.first.bytes;
      if (bytes == null) throw Exception('No se pudo leer el archivo');

      final plan = ExcelParser.parse(bytes);

      _days      = plan.days;
      _loads     = plan.loads;
      _nutrition = plan.nutrition;
      _lastImport = DateTime.now().toIso8601String();

      await DataService.savePlan(_days);
      await DataService.saveLoads(_loads);
      await DataService.saveNutrition(_nutrition);
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

  // ── Exercise completion (session state, not persisted) ─────────
  void toggleExercise(String dayName, String ejercicio) {
    final day = _days.where((d) => d.name == dayName).firstOrNull;
    if (day == null) return;
    final ex = day.exercises.where((e) => e.nombre == ejercicio).firstOrNull;
    if (ex == null) return;
    ex.hecho = !ex.hecho;
    notifyListeners();
  }

  void setExerciseRealWeight(String dayName, String ejercicio, double? kg) {
    final day = _days.where((d) => d.name == dayName).firstOrNull;
    if (day == null) return;
    final ex = day.exercises.where((e) => e.nombre == ejercicio).firstOrNull;
    if (ex == null) return;
    ex.pesoReal = kg;
    notifyListeners();
  }

  int completedCount(String dayName) {
    final day = _days.where((d) => d.name == dayName).firstOrNull;
    return day?.exercises.where((e) => e.hecho).length ?? 0;
  }
}

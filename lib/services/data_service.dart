import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/exercise.dart';
import '../models/load_exercise.dart';
import '../models/progress_entry.dart';
import '../models/shopping_item.dart';

class DataService {
  static const _keyStart   = 'start_date';   // ISO del lunes de la semana 1
  static const _keyImport  = 'last_import';
  static const _filePlan   = 'training_plan.json';
  static const _fileCargas = 'cargas.json';      // {percents, exercises}
  static const _fileRms    = 'rms.json';         // {nombre: kg}
  static const _fileDone   = 'completed.json';   // {week: [day|ejercicio,...]}
  static const _fileProgress = 'progress.json';
  static const _fileShopping = 'shopping.json';

  // ── SharedPreferences ─────────────────────────────────────────
  static Future<DateTime?> getStartDate() async {
    final p = await SharedPreferences.getInstance();
    final s = p.getString(_keyStart);
    return s == null ? null : DateTime.tryParse(s);
  }

  static Future<void> setStartDate(DateTime d) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_keyStart, d.toIso8601String());
  }

  static Future<String?> getLastImport() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_keyImport);
  }

  static Future<void> setLastImport(String dt) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_keyImport, dt);
  }

  // ── File helpers ──────────────────────────────────────────────
  static Future<File> _file(String name) async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$name');
  }

  static Future<void> _write(String name, String json) async {
    final f = await _file(name);
    await f.writeAsString(json, flush: true);
  }

  static Future<String?> _read(String name) async {
    try {
      final f = await _file(name);
      if (await f.exists()) return await f.readAsString();
    } catch (_) {}
    return null;
  }

  // ── Training Plan ─────────────────────────────────────────────
  static Future<void> savePlan(List<TrainingDay> days) async =>
      _write(_filePlan, jsonEncode(days.map((d) => d.toJson()).toList()));

  static Future<List<TrainingDay>> loadPlan() async {
    final raw = await _read(_filePlan);
    if (raw == null) return [];
    return (jsonDecode(raw) as List)
        .map((j) => TrainingDay.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  // ── Cargas (ejercicios + % por semana) ────────────────────────
  static Future<void> saveCargas(List<LoadExercise> ex, List<double> percents) async =>
      _write(_fileCargas, jsonEncode({
        'percents': percents,
        'exercises': ex.map((e) => e.toJson()).toList(),
      }));

  static Future<(List<LoadExercise>, List<double>)> loadCargas() async {
    final raw = await _read(_fileCargas);
    if (raw == null) return (<LoadExercise>[], <double>[]);
    final j = jsonDecode(raw) as Map<String, dynamic>;
    final ex = (j['exercises'] as List? ?? [])
        .map((e) => LoadExercise.fromJson(e as Map<String, dynamic>))
        .toList();
    final pc = (j['percents'] as List? ?? []).map((v) => (v as num).toDouble()).toList();
    return (ex, pc);
  }

  // ── 1RMs del usuario ──────────────────────────────────────────
  static Future<void> saveRms(Map<String, double> rms) async =>
      _write(_fileRms, jsonEncode(rms));

  static Future<Map<String, double>> loadRms() async {
    final raw = await _read(_fileRms);
    if (raw == null) return {};
    return (jsonDecode(raw) as Map<String, dynamic>)
        .map((k, v) => MapEntry(k, (v as num).toDouble()));
  }

  // ── Completado por semana ─────────────────────────────────────
  static Future<void> saveCompleted(Map<int, Set<String>> done) async =>
      _write(_fileDone, jsonEncode(
        done.map((k, v) => MapEntry(k.toString(), v.toList())),
      ));

  static Future<Map<int, Set<String>>> loadCompleted() async {
    final raw = await _read(_fileDone);
    if (raw == null) return {};
    final j = jsonDecode(raw) as Map<String, dynamic>;
    return j.map((k, v) =>
        MapEntry(int.parse(k), (v as List).map((e) => e.toString()).toSet()));
  }

  // ── Progress ──────────────────────────────────────────────────
  static Future<void> saveProgress(List<ProgressEntry> entries) async =>
      _write(_fileProgress, jsonEncode(entries.map((e) => e.toJson()).toList()));

  static Future<List<ProgressEntry>> loadProgress() async {
    final raw = await _read(_fileProgress);
    if (raw == null) return [];
    return (jsonDecode(raw) as List)
        .map((j) => ProgressEntry.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  // ── Shopping list ─────────────────────────────────────────────
  static Future<void> saveShopping(List<ShoppingItem> items) async =>
      _write(_fileShopping, jsonEncode(items.map((s) => s.toJson()).toList()));

  static Future<List<ShoppingItem>> loadShopping() async {
    final raw = await _read(_fileShopping);
    if (raw == null) return [];
    return (jsonDecode(raw) as List)
        .map((j) => ShoppingItem.fromJson(j as Map<String, dynamic>))
        .toList();
  }
}

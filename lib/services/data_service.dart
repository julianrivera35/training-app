import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/exercise.dart';
import '../models/weekly_load.dart';
import '../models/nutrition_plan.dart';
import '../models/progress_entry.dart';

class DataService {
  static const _keyWeek    = 'current_week';
  static const _keyImport  = 'last_import';
  static const _filePlan   = 'training_plan.json';
  static const _fileLoads  = 'weekly_loads.json';
  static const _fileNutri  = 'nutrition.json';
  static const _fileProgress = 'progress.json';

  // ── SharedPreferences ─────────────────────────────────────────
  static Future<int> getCurrentWeek() async {
    final p = await SharedPreferences.getInstance();
    return p.getInt(_keyWeek) ?? 1;
  }

  static Future<void> setCurrentWeek(int week) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(_keyWeek, week);
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
  static Future<void> savePlan(List<TrainingDay> days) async {
    final json = jsonEncode(days.map((d) => d.toJson()).toList());
    await _write(_filePlan, json);
  }

  static Future<List<TrainingDay>> loadPlan() async {
    final raw = await _read(_filePlan);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list.map((j) => TrainingDay.fromJson(j as Map<String, dynamic>)).toList();
  }

  // ── Weekly Loads ──────────────────────────────────────────────
  static Future<void> saveLoads(List<WeeklyLoad> loads) async {
    final json = jsonEncode(loads.map((l) => l.toJson()).toList());
    await _write(_fileLoads, json);
  }

  static Future<List<WeeklyLoad>> loadLoads() async {
    final raw = await _read(_fileLoads);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list.map((j) => WeeklyLoad.fromJson(j as Map<String, dynamic>)).toList();
  }

  // ── Nutrition ─────────────────────────────────────────────────
  static Future<void> saveNutrition(NutritionPlan plan) async {
    await _write(_fileNutri, jsonEncode(plan.toJson()));
  }

  static Future<NutritionPlan> loadNutrition() async {
    final raw = await _read(_fileNutri);
    if (raw == null) return NutritionPlan.defaultPlan();
    return NutritionPlan.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  // ── Progress ──────────────────────────────────────────────────
  static Future<void> saveProgress(List<ProgressEntry> entries) async {
    final json = jsonEncode(entries.map((e) => e.toJson()).toList());
    await _write(_fileProgress, json);
  }

  static Future<List<ProgressEntry>> loadProgress() async {
    final raw = await _read(_fileProgress);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list.map((j) => ProgressEntry.fromJson(j as Map<String, dynamic>)).toList();
  }
}

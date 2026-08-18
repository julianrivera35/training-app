import 'package:excel/excel.dart';
import '../models/exercise.dart';
import '../models/weekly_load.dart';
import '../models/nutrition_plan.dart';

class ParsedPlan {
  final List<TrainingDay> days;
  final List<WeeklyLoad> loads;
  final NutritionPlan nutrition;
  ParsedPlan({required this.days, required this.loads, required this.nutrition});
}

class ExcelParser {
  static const _dayNames = [
    'LUNES', 'MARTES', 'MIÉRCOLES', 'MIERCOLES',
    'JUEVES', 'VIERNES', 'SÁBADO', 'SABADO', 'DOMINGO',
  ];

  // ── public entry ──────────────────────────────────────────────
  static ParsedPlan parse(List<int> bytes) {
    final excel = Excel.decodeBytes(bytes);
    final days   = _parseSemanal(excel);
    final loads  = _parseCargas(excel);
    final nutri  = _parseNutricion(excel);
    return ParsedPlan(days: days, loads: loads, nutrition: nutri);
  }

  // ── PROGRAMA SEMANAL ─────────────────────────────────────────
  static List<TrainingDay> _parseSemanal(Excel excel) {
    final sheet = excel.tables['PROGRAMA SEMANAL'];
    if (sheet == null) return [];

    final days = <TrainingDay>[];
    TrainingDay? current;
    String currentSection = '';
    bool headerSkipped = false;

    for (final row in sheet.rows) {
      if (row.isEmpty) continue;
      final a = _s(row, 0);
      final b = _s(row, 1);
      final c = _s(row, 2);
      final d = _s(row, 3);

      // Skip title row and column header row
      if (!headerSkipped && (a.contains('PROGRAMA') || a.contains('BLOQUE'))) {
        headerSkipped = true; continue;
      }
      if (a == 'BLOQUE' || a == 'EJERCICIO') continue;

      // Detect if row is "merged" (col B null means col A spans full width)
      final isMerged = _isMerged(row);

      if (isMerged) {
        // Day header?
        if (_dayNames.any((d2) => a.toUpperCase().contains(d2))) {
          if (current != null) days.add(current);
          current = TrainingDay(name: a, exercises: []);
          currentSection = '';
        } else if (current != null) {
          // Section header within a day
          currentSection = a;
        }
      } else if (b.isNotEmpty && current != null) {
        // Exercise row
        current.exercises.add(Exercise(
          bloque: a,
          nombre: b,
          peso: c,
          reps: d,
          series: _s(row, 4),
          descanso: _s(row, 5),
          instruccion: _s(row, 6),
          seccion: currentSection,
          dia: current.name,
        ));
      }
    }
    if (current != null) days.add(current);
    return days;
  }

  // ── CARGAS Y PROGRESIÓN ───────────────────────────────────────
  static List<WeeklyLoad> _parseCargas(Excel excel) {
    // try common sheet name variants
    Sheet? sheet;
    for (final name in ['CARGAS Y PROGRESIÓN', 'CARGAS Y PROGRESION', 'CARGAS']) {
      sheet = excel.tables[name];
      if (sheet != null) break;
    }
    if (sheet == null) return [];

    final loads = <WeeklyLoad>[];
    int dataStart = 0;

    // Find header row (contains "EJERCICIO" and "1RM")
    for (int r = 0; r < sheet.rows.length; r++) {
      final row = sheet.rows[r];
      final rowStr = row.map((c) => _s2(c)).join(' ').toUpperCase();
      if (rowStr.contains('EJERCICIO') && rowStr.contains('1RM')) {
        dataStart = r + 1;
        break;
      }
    }

    for (int r = dataStart; r < sheet.rows.length; r++) {
      final row = sheet.rows[r];
      if (row.isEmpty) continue;
      final a = _s(row, 0);
      final b = _s(row, 1);

      // Skip separators and "Real" rows
      if (a.startsWith('──') || b.startsWith('→')) continue;
      if (b.isEmpty) continue;

      // Plan kg are in columns 5-12 (0-indexed)
      final plan = <double>[];
      for (int c = 5; c <= 12; c++) {
        final v = _n(row, c);
        if (v != null) plan.add(v);
      }
      if (plan.isEmpty) continue;

      loads.add(WeeklyLoad(
        grupo: a,
        nombre: b,
        dia: _s(row, 2),
        orm: _n(row, 3) ?? 0,
        unidad: _s(row, 4),
        planKg: plan,
      ));
    }
    return loads;
  }

  // ── NUTRICIÓN ─────────────────────────────────────────────────
  static NutritionPlan _parseNutricion(Excel excel) {
    // Try to find macros in the nutrition sheet; fall back to default
    Sheet? sheet;
    for (final name in ['NUTRICIÓN', 'NUTRICION', 'NUTRICIÓN']) {
      sheet = excel.tables[name];
      if (sheet != null) break;
    }
    if (sheet == null) return NutritionPlan.defaultPlan();

    int protein = 0, carbs = 0, fat = 0, kcal = 0;
    for (final row in sheet.rows) {
      final rowText = row.map((c) => _s2(c).toUpperCase()).join(' ');
      // Look for macro rows
      if (rowText.contains('PROTEÍNA') || rowText.contains('PROTEINA')) {
        for (int c = 0; c < row.length; c++) {
          final v = _n2(row[c]);
          if (v != null && v > 50) { protein = v.toInt(); break; }
        }
      } else if (rowText.contains('CARBOH')) {
        for (int c = 0; c < row.length; c++) {
          final v = _n2(row[c]);
          if (v != null && v > 50) { carbs = v.toInt(); break; }
        }
      } else if (rowText.contains('GRASA')) {
        for (int c = 0; c < row.length; c++) {
          final v = _n2(row[c]);
          if (v != null && v > 10) { fat = v.toInt(); break; }
        }
      } else if (rowText.contains('CALORÍA') || rowText.contains('CALORIA') || rowText.contains('KCAL')) {
        for (int c = 0; c < row.length; c++) {
          final v = _n2(row[c]);
          if (v != null && v > 500) { kcal = v.toInt(); break; }
        }
      }
    }

    // If we found meaningful values, use them; else default
    if (protein > 0 && kcal > 0) {
      final def = NutritionPlan.defaultPlan();
      return NutritionPlan(
        proteinaTotal: protein,
        carbosTotal: carbs > 0 ? carbs : def.carbosTotal,
        grasasTotal: fat > 0 ? fat : def.grasasTotal,
        caloriasTotal: kcal,
        comidas: def.comidas,
        suplementos: def.suplementos,
      );
    }
    return NutritionPlan.defaultPlan();
  }

  // ── helpers ───────────────────────────────────────────────────
  static bool _isMerged(List<Data?> row) {
    if (row.isEmpty || row[0]?.value == null) return false;
    // If columns 1-3 are all null → merged row
    for (int i = 1; i <= 3; i++) {
      if (row.length > i && row[i]?.value != null) return false;
    }
    return true;
  }

  static String _s(List<Data?> row, int col) {
    if (col >= row.length) return '';
    return _s2(row[col]);
  }

  static String _s2(Data? d) {
    if (d?.value == null) return '';
    final v = d!.value!;
    if (v is TextCellValue) return (v.value.text ?? '').trim();
    if (v is IntCellValue) return v.value.toString();
    if (v is DoubleCellValue) {
      final dv = v.value;
      return dv == dv.truncateToDouble() ? dv.toInt().toString() : dv.toStringAsFixed(1);
    }
    if (v is BoolCellValue) return v.value.toString();
    return '';
  }

  static double? _n(List<Data?> row, int col) {
    if (col >= row.length) return null;
    return _n2(row[col]);
  }

  static double? _n2(Data? d) {
    if (d?.value == null) return null;
    final v = d!.value!;
    if (v is IntCellValue) return v.value.toDouble();
    if (v is DoubleCellValue) return v.value;
    if (v is TextCellValue) return double.tryParse((v.value.text ?? '').replaceAll(',', '.'));
    return null;
  }
}

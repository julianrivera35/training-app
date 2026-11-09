import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:excel/excel.dart';
import '../models/exercise.dart';
import '../models/load_exercise.dart';
import '../models/shopping_item.dart';

class ParsedPlan {
  final List<TrainingDay> days;
  final List<LoadExercise> loadExercises; // ejercicios con 1RM (cargas)
  final List<double> weekPercents;        // % por semana del bloque (8)
  final List<ShoppingItem> shopping;
  ParsedPlan({
    required this.days,
    required this.loadExercises,
    required this.weekPercents,
    required this.shopping,
  });
}

class ExcelParser {
  static const _dayNames = [
    'LUNES', 'MARTES', 'MIÉRCOLES', 'MIERCOLES',
    'JUEVES', 'VIERNES', 'SÁBADO', 'SABADO', 'DOMINGO',
  ];

  // ── public entry ──────────────────────────────────────────────
  static ParsedPlan parse(List<int> bytes) {
    final excel = Excel.decodeBytes(_sanitize(bytes));
    final days   = _parseSemanal(excel);
    final cargas = _parseCargas(excel);
    final shop   = _parseMercado(excel);
    return ParsedPlan(
      days: days,
      loadExercises: cargas.$1,
      weekPercents: cargas.$2,
      shopping: shop,
    );
  }

  // ── LISTA DEL MERCADO ─────────────────────────────────────────
  static List<ShoppingItem> _parseMercado(Excel excel) {
    Sheet? sheet;
    for (final name in [
      'LISTA DEL MERCADO', 'LISTA DE MERCADO', 'MERCADO', 'LISTA DEL MERCADO MENSUAL'
    ]) {
      sheet = excel.tables[name];
      if (sheet != null) break;
    }
    if (sheet == null) return [];

    final items = <ShoppingItem>[];
    String currentCat = 'General';
    bool headerPassed = false;

    for (final row in sheet.rows) {
      if (row.isEmpty) continue;
      final a = _s(row, 0);
      final b = _s(row, 1);

      if (!headerPassed) {
        final rowStr = row.map((c) => _s2(c)).join(' ').toUpperCase();
        if (rowStr.contains('ÍTEM') || rowStr.contains('ITEM')) headerPassed = true;
        continue;
      }

      // Category header: full-width row (no item in col B).
      if (b.isEmpty) {
        if (a.isNotEmpty) currentCat = a.trim();
        continue;
      }

      // Item row: col A is the checkbox (☐ / ✓), col B the item name.
      items.add(ShoppingItem(
        categoria: currentCat,
        nombre: b,
        cantidad: _s(row, 2),
        frecuencia: _s(row, 3),
        notas: _s(row, 4),
        comprado: a.contains('✓') || a.contains('☑'),
      ));
    }
    return items;
  }

  /// Some tools (e.g. certain Excel exporters) write absolute relationship
  /// targets like `Target="/xl/worksheets/sheet1.xml"`. The `excel` package
  /// resolves them as `findFile('xl/' + target)`, producing `xl//xl/...`,
  /// which returns null and crashes with "Null check operator used on a null
  /// value". We rewrite those targets to relative paths before decoding.
  static List<int> _sanitize(List<int> bytes) {
    try {
      final input = ZipDecoder().decodeBytes(bytes);
      var changed = false;
      final output = Archive();
      for (final f in input.files) {
        if (!f.isFile) continue;
        var data = f.content as List<int>;
        if (f.name.endsWith('.rels')) {
          final xml = utf8.decode(data, allowMalformed: true);
          // /xl/worksheets/sheet1.xml -> worksheets/sheet1.xml, etc.
          final fixed = xml.replaceAll('Target="/xl/', 'Target="');
          if (fixed != xml) {
            data = utf8.encode(fixed);
            changed = true;
          }
        } else if (f.name.startsWith('xl/worksheets/') &&
            f.name.endsWith('.xml')) {
          final xml = utf8.decode(data, allowMalformed: true);
          // Cells declared as inline strings but with no <t> element
          // (e.g. `<c ... t="inlineStr"></c>` or self-closed) crash the
          // parser at `findAllElements('t').first`. Drop the type so they
          // are treated as empty cells.
          final fixed = xml
              .replaceAllMapped(
                RegExp(r'<c\b([^>]*)\st="inlineStr"([^>]*)>\s*</c>'),
                (m) => '<c${m[1]}${m[2]}></c>',
              )
              .replaceAllMapped(
                RegExp(r'<c\b([^>]*)\st="inlineStr"([^>]*)/>'),
                (m) => '<c${m[1]}${m[2]}/>',
              );
          if (fixed != xml) {
            data = utf8.encode(fixed);
            changed = true;
          }
        }
        output.addFile(ArchiveFile(f.name, data.length, data));
      }
      if (!changed) return bytes;
      final out = ZipEncoder().encode(output);
      return out ?? bytes;
    } catch (_) {
      // If anything goes wrong, fall back to the original bytes.
      return bytes;
    }
  }

  // ── PROGRAMA SEMANAL ─────────────────────────────────────────
  static List<TrainingDay> _parseSemanal(Excel excel) {
    final sheet = excel.tables['PROGRAMA SEMANAL'];
    if (sheet == null) return [];

    final days = <TrainingDay>[];
    final warmup = <Exercise>[];   // ejercicios de "TODOS LOS DÍAS" (antes del 1er día)
    String warmupSection = '🔥 Activación + Prehab (diario)';
    TrainingDay? current;
    String currentSection = '';
    String? pendingActivity; // encabezado 🏊/🧘 esperando su fila de detalle
    bool headerSkipped = false;

    for (final row in sheet.rows) {
      if (row.isEmpty) continue;
      final a = _s(row, 0);
      final b = _s(row, 1);
      final c = _s(row, 2);
      final d = _s(row, 3);

      // Skip everything before the column-header row (título, leyenda, cardio,
      // "BLOQUE/EJERCICIO | ..."). El encabezado puede estar en A ("BLOQUE",
      // formato viejo) o en B ("EJERCICIO", formato nuevo).
      if (!headerSkipped) {
        if (a.toUpperCase().startsWith('BLOQUE') || b.toUpperCase().startsWith('EJERCICIO')) {
          headerSkipped = true;
        }
        continue;
      }

      // Detect if row is "merged" (col B null means col A spans full width)
      final isMerged = _isMerged(row);

      if (isMerged) {
        // Day header — debe EMPEZAR con el nombre del día (no solo contenerlo),
        // para que "🧘 FLEXIBILIDAD POST-MARTES" no se tome como un día nuevo.
        if (_isDayHeader(a)) {
          if (current != null) days.add(current);
          current = TrainingDay(name: a, exercises: []);
          currentSection = '';
          pendingActivity = null;
        } else if (current == null) {
          // Antes del primer día: encabezado del calentamiento diario.
          final up = a.toUpperCase();
          if (up.contains('TODOS LOS DÍAS') || up.contains('ACTIVACIÓN') || up.contains('PREHAB')) {
            warmupSection = a.trim();
          }
        } else {
          if (_isActivityHeader(a)) {
            // Bloque de natación/flexibilidad: el título va ahora; el detalle
            // (qué hacer) viene en la siguiente fila de ancho completo.
            pendingActivity = a;
            currentSection = a;
          } else if (pendingActivity != null) {
            // Fila de detalle del bloque de actividad (solo columna A).
            current.exercises.add(Exercise(
              bloque: _activityBloque(pendingActivity),
              nombre: pendingActivity,
              instruccion: a,
              descanso: _extractDescanso(a),
              seccion: currentSection,
              dia: current.name,
            ));
            pendingActivity = null;
          } else {
            // Encabezado de sección normal dentro del día (incluye 🌅 MAÑANA / 🌆 TARDE).
            currentSection = a;
          }
        }
      } else if (b.isNotEmpty && _hasLetters(b)) {
        // Exercise row (filtra filas basura cuyo "nombre" es solo un número)
        pendingActivity = null;
        final ex = Exercise(
          bloque: a,
          nombre: b,
          peso: c,
          reps: d,
          series: _s(row, 4),
          descanso: _s(row, 5),
          instruccion: _s(row, 6),
          seccion: current == null ? warmupSection : currentSection,
          dia: current?.name ?? '',
        );
        if (current == null) {
          warmup.add(ex);   // calentamiento diario (antes del primer día)
        } else {
          current.exercises.add(ex);
        }
      }
    }
    if (current != null) days.add(current);

    // Prepend el calentamiento diario a cada día (copias independientes).
    if (warmup.isNotEmpty) {
      for (final day in days) {
        final clones = warmup
            .map((w) => Exercise(
                  bloque: w.bloque,
                  nombre: w.nombre,
                  peso: w.peso,
                  reps: w.reps,
                  series: w.series,
                  descanso: w.descanso,
                  instruccion: w.instruccion,
                  seccion: w.seccion,
                  dia: day.name,
                ))
            .toList();
        day.exercises.insertAll(0, clones);
      }
    }

    return days;
  }

  /// A day header must START with a weekday name (after stripping any leading
  /// emoji/symbols), so "🧘 FLEXIBILIDAD POST-MARTES" is NOT a new day.
  static bool _isDayHeader(String a) {
    final up = a.replaceAll(RegExp(r'^[^A-Za-zÁÉÍÓÚÑáéíóúñ]+'), '').toUpperCase();
    return _dayNames.any((d) => up.startsWith(d));
  }

  // ── CARGAS Y PROGRESIÓN (1RM × % por semana) ──────────────────
  static const List<double> _defaultPercents = [75, 78, 80, 82, 85, 87, 88, 72];

  /// Devuelve (ejercicios con 1RM, porcentajes de las 8 semanas del bloque).
  static (List<LoadExercise>, List<double>) _parseCargas(Excel excel) {
    Sheet? sheet;
    for (final name in ['CARGAS Y PROGRESIÓN', 'CARGAS Y PROGRESION', 'CARGAS']) {
      sheet = excel.tables[name];
      if (sheet != null) break;
    }
    if (sheet == null) return (<LoadExercise>[], _defaultPercents);

    // Fila de encabezado: la que contiene "1RM".
    int headerRow = -1;
    for (int r = 0; r < sheet.rows.length; r++) {
      final s = sheet.rows[r].map((c) => _s2(c)).join(' ').toUpperCase();
      if (s.contains('1RM')) { headerRow = r; break; }
    }
    if (headerRow < 0) return (<LoadExercise>[], _defaultPercents);

    // Porcentajes por semana: celdas del encabezado tipo "SEM 1\n75%".
    final percents = <double>[];
    for (final cell in sheet.rows[headerRow]) {
      final txt = _s2(cell);
      final m = RegExp(r'(\d{1,3})\s*%').firstMatch(txt);
      if (txt.toUpperCase().contains('SEM') && m != null) {
        percents.add(double.parse(m.group(1)!));
      }
    }

    // Ejercicios: nombre en col A, día en col B (solo filas con un día real).
    final exercises = <LoadExercise>[];
    final seen = <String>{};
    for (int r = headerRow + 1; r < sheet.rows.length; r++) {
      final a = _s(sheet.rows[r], 0);
      final b = _s(sheet.rows[r], 1);
      if (!_hasLetters(a)) continue;
      final up = a.toUpperCase();
      if (up.contains('CÓMO USAR') || up.contains('COMO USAR')) break;
      if (!_looksLikeDay(b)) continue; // descarta encabezados de sección
      final key = a.toLowerCase();
      if (seen.contains(key)) continue;
      seen.add(key);
      exercises.add(LoadExercise(nombre: a, dia: b));
    }
    return (exercises, percents.isNotEmpty ? percents : _defaultPercents);
  }

  static bool _hasLetters(String s) =>
      RegExp(r'[A-Za-zÁÉÍÓÚÑáéíóúñ]').hasMatch(s);

  static bool _looksLikeDay(String s) {
    final up = s
        .toUpperCase()
        .replaceAll('Á', 'A').replaceAll('É', 'E').replaceAll('Í', 'I')
        .replaceAll('Ó', 'O').replaceAll('Ú', 'U');
    return const ['LUN', 'MAR', 'MIE', 'JUE', 'VIE', 'SAB', 'DOM']
        .any((d) => up.contains(d));
  }

  // ── helpers ───────────────────────────────────────────────────
  /// Full-width rows that introduce a swimming / flexibility activity block,
  /// e.g. "🏊 NATACIÓN HIIT — ..." or "🧘 FLEXIBILIDAD ...". The following
  /// full-width row holds the actual "what to do" detail.
  static bool _isActivityHeader(String a) {
    final stripped =
        a.replaceAll(RegExp(r'^[^A-Za-zÁÉÍÓÚÑáéíóúñ]+'), '').toUpperCase();
    return a.startsWith('🏊') ||
        a.startsWith('🧘') ||
        stripped.startsWith('NATACIÓN') ||
        stripped.startsWith('NATACION') ||
        stripped.startsWith('FLEXIBILIDAD');
  }

  static String _activityBloque(String header) {
    final up = header.toUpperCase();
    if (up.contains('NATACIÓN') || up.contains('NATACION')) return 'NATACIÓN';
    if (up.contains('FLEXIBILIDAD')) return 'FLEXIBILIDAD';
    return 'MOVILIDAD';
  }

  /// Best-effort extraction of a rest hint like "1:30 min" from a paragraph
  /// such as "8 × 50m all-out + 1:30 min descanso activo ...".
  static String _extractDescanso(String text) {
    final m = RegExp(
      r'(\d[\d:.]*\s*(?:min|minutos|seg|segundos|s))\s*(?:de\s+)?descanso',
      caseSensitive: false,
    ).firstMatch(text);
    return m != null ? m.group(1)!.trim() : '';
  }

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

}

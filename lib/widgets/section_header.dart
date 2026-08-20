import 'package:flutter/material.dart';
import '../models/exercise.dart';
import '../theme/app_theme.dart';

/// Section divider shown inside a day's exercise list (Calentamiento,
/// 🌅 Mañana, 🌆 Tarde, Flexibilidad, etc.).
class SectionHeader extends StatelessWidget {
  final String text;
  const SectionHeader(this.text, {super.key});

  Color get _accent {
    final up = text.toUpperCase();
    if (up.contains('MAÑANA')) return AppTheme.orange;
    if (up.contains('TARDE') || up.contains('PM')) return const Color(0xFF5E35B1);
    if (up.contains('FLEXIBILID')) return const Color(0xFF4527A0);
    if (up.contains('NATACIÓN') || up.contains('NATACION') || up.contains('PISCINA')) return AppTheme.blue;
    if (up.contains('ACTIVACIÓN') || up.contains('TODOS LOS DÍAS') || up.contains('PREHAB')) return const Color(0xFFEF6C00);
    if (up.contains('ALTERNATIVA') || up.contains('SECO')) return AppTheme.navy;
    return AppTheme.navy;
  }

  @override
  Widget build(BuildContext context) {
    final clean = text.replaceAll('\n', ' ').trim();
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border(left: BorderSide(color: _accent, width: 4)),
      ),
      child: Text(
        clean,
        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: _accent, height: 1.25),
      ),
    );
  }
}

/// Builds [SectionHeader]s between exercises whenever the `seccion` changes.
List<Widget> sectionedExercises(
  List<Exercise> exercises,
  Widget Function(Exercise) cardBuilder,
) {
  final out = <Widget>[];
  String? last;
  for (final e in exercises) {
    if (e.seccion != last) {
      last = e.seccion;
      if (e.seccion.trim().isNotEmpty) out.add(SectionHeader(e.seccion));
    }
    out.add(cardBuilder(e));
  }
  return out;
}

bool isDoubleSession(String dayName) =>
    dayName.toUpperCase().contains('DOBLE SESIÓN') ||
    dayName.toUpperCase().contains('DOBLE SESION');

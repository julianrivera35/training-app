import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/exercise.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/exercise_card.dart';
import '../widgets/section_header.dart';

class WeekScreen extends StatefulWidget {
  const WeekScreen({super.key});
  @override State<WeekScreen> createState() => _WeekScreenState();
}

class _WeekScreenState extends State<WeekScreen> {
  String? _expanded;

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Semana ${p.currentWeek} — ${p.currentPhase}'),
        backgroundColor: AppTheme.navy,
      ),
      body: !p.hasPlan
          ? _noplan()
          : p.days.isEmpty
              ? const Center(child: Text('No hay días cargados'))
              : ListView(
                  padding: const EdgeInsets.only(top: 8, bottom: 100),
                  children: p.days.map((day) => _dayCard(context, p, day)).toList(),
                ),
    );
  }

  Widget _dayCard(BuildContext context, AppProvider p, TrainingDay day) {
    final isToday = _noAccents(day.name.toUpperCase()).startsWith(_noAccents(p.todayDayName));
    final isExpanded = _expanded == day.name;
    final done = p.completedCount(day.name);
    final total = day.exercises.length;
    final pct = total == 0 ? 0.0 : done / total;
    final (weekday, focus) = _split(day.name);
    final accent = isToday ? AppTheme.orange : AppTheme.navy;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isToday ? Border.all(color: AppTheme.orange, width: 1.5) : null,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = isExpanded ? null : day.name),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
              child: Row(
                children: [
                  Container(width: 5, height: 46,
                    decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(3))),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Text(weekday, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: accent, letterSpacing: 0.3)),
                          if (isToday) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(color: AppTheme.orange, borderRadius: BorderRadius.circular(5)),
                              child: const Text('HOY', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900)),
                            ),
                          ],
                        ]),
                        if (focus.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(focus,
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF78909C))),
                        ],
                        const SizedBox(height: 9),
                        Row(children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: pct, minHeight: 6,
                                backgroundColor: const Color(0xFFEDEFF3),
                                valueColor: AlwaysStoppedAnimation(done == total && total > 0 ? AppTheme.green : accent),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text('$done/$total',
                            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700,
                              color: done == total && total > 0 ? AppTheme.green : const Color(0xFF90A4AE))),
                        ]),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: const Color(0xFFBBBBBB)),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            const Divider(height: 1, color: Color(0xFFF0F0F0)),
            ...sectionedExercises(day.exercises, (ex) => ExerciseCard(
              exercise: ex,
              isDone: p.isDone(day.name, ex.nombre),
              plannedKg: p.plannedWeightFor(ex.nombre),
              onToggle: () => p.toggleDone(day.name, ex.nombre),
            )),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  /// "LUNES — FUERZA INFERIOR" → ("LUNES", "Fuerza inferior")
  (String, String) _split(String name) {
    final clean = name.replaceAll(RegExp(r'^[^\wÁÉÍÓÚáéíóúÑñ\s]+\s*'), '').trim();
    final parts = clean.split(RegExp(r'\s*[—–-]\s*'));
    final weekday = parts.first.trim().toUpperCase();
    final focus = parts.length > 1 ? _titleCase(parts.sublist(1).join(' · ').trim()) : '';
    return (weekday, focus);
  }

  String _titleCase(String s) => s.isEmpty ? s
      : s[0].toUpperCase() + s.substring(1).toLowerCase();

  String _noAccents(String s) => s
      .replaceAll('Á','A').replaceAll('É','E').replaceAll('Í','I')
      .replaceAll('Ó','O').replaceAll('Ú','U');

  Widget _noplan() => const Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.calendar_month_outlined, size: 64, color: Color(0xFFCFD8DC)),
      SizedBox(height: 16),
      Text('Importa tu Excel primero', style: TextStyle(fontSize: 18, color: Color(0xFF546E7A))),
    ]),
  );
}

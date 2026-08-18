import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/exercise.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/exercise_card.dart';

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
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: p.days.map((day) => _dayCard(context, p, day)).toList(),
                ),
    );
  }

  Widget _dayCard(BuildContext context, AppProvider p, TrainingDay day) {
    final isToday = day.name.toUpperCase().contains(p.todayDayName);
    final isExpanded = _expanded == day.name;
    final done = p.completedCount(day.name);
    final total = day.exercises.length;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: isToday ? Border.all(color: AppTheme.orange, width: 2) : null,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          // Header
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => setState(() => _expanded = isExpanded ? null : day.name),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 6, height: 40,
                    decoration: BoxDecoration(
                      color: isToday ? AppTheme.orange : AppTheme.navy,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Text(
                            _cleanDayName(day.name),
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: isToday ? AppTheme.orange : AppTheme.navy,
                            ),
                          ),
                          if (isToday) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.orange, borderRadius: BorderRadius.circular(5)),
                              child: const Text('HOY', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800)),
                            ),
                          ],
                        ]),
                        const SizedBox(height: 3),
                        Text(
                          '$total ejercicios${done > 0 ? ' · $done completados' : ''}',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF90A4AE)),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: const Color(0xFF90A4AE),
                  ),
                ],
              ),
            ),
          ),
          // Exercise list (expanded)
          if (isExpanded) ...[
            const Divider(height: 1, color: Color(0xFFF0F0F0)),
            ...day.exercises.map((ex) => ExerciseCard(
              exercise: ex,
              plannedKg: p.plannedWeightFor(ex.nombre),
              onToggle: () => p.toggleExercise(day.name, ex.nombre),
              onWeightLogged: (kg) => p.setExerciseRealWeight(day.name, ex.nombre, kg),
            )),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  String _cleanDayName(String name) {
    // "⚡ LUNES — FUERZA EXPLOSIVA" → "LUNES — FUERZA EXPLOSIVA"
    return name.replaceAll(RegExp(r'^[^\wÁÉÍÓÚáéíóúÑñ\s]+\s*'), '').trim();
  }

  Widget _noplan() => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.calendar_month_outlined, size: 64, color: Color(0xFFCFD8DC)),
      const SizedBox(height: 16),
      const Text('Importa tu Excel primero', style: TextStyle(fontSize: 18, color: Color(0xFF546E7A))),
    ]),
  );
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/exercise_card.dart';

class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    final today = p.todayTraining;
    final fmt = DateFormat('EEEE d MMMM yyyy', 'es');
    final now = DateTime.now();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 140,
            pinned: true,
            backgroundColor: AppTheme.navy,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                p.todayDayName,
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1B2F5B), Color(0xFF1565C0)],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 48, 20, 50),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fmt.format(now),
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _badge('Sem ${p.currentWeek}', AppTheme.orange),
                          const SizedBox(width: 8),
                          _badge(p.currentPhase, Colors.white24),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          if (!p.hasPlan)
            SliverFillRemaining(child: _noplan(context))
          else if (today == null)
            SliverFillRemaining(child: _restDay(p.todayDayName))
          else ...[
            // Progress bar
            SliverToBoxAdapter(
              child: _progressHeader(today.exercises.length, p.completedCount(today.name)),
            ),
            // Exercise list
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) {
                  final ex = today.exercises[i];
                  return ExerciseCard(
                    exercise: ex,
                    plannedKg: p.plannedWeightFor(ex.nombre),
                    onToggle: () => p.toggleExercise(today.name, ex.nombre),
                    onWeightLogged: (kg) => p.setExerciseRealWeight(today.name, ex.nombre, kg),
                  );
                },
                childCount: today.exercises.length,
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ],
      ),
    );
  }

  Widget _badge(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
    child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
  );

  Widget _progressHeader(int total, int done) {
    final pct = total == 0 ? 0.0 : done / total;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$done / $total ejercicios',
                style: const TextStyle(fontSize: 13, color: Color(0xFF546E7A), fontWeight: FontWeight.w600)),
              Text('${(pct * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 13,
                  color: pct == 1 ? AppTheme.green : AppTheme.navy,
                  fontWeight: FontWeight.w700,
                )),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct, minHeight: 5,
              backgroundColor: const Color(0xFFE0E0E0),
              color: pct == 1 ? AppTheme.green : AppTheme.blue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _noplan(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.upload_file_outlined, size: 72, color: Color(0xFFCFD8DC)),
        const SizedBox(height: 20),
        const Text('Sin plan cargado', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF546E7A))),
        const SizedBox(height: 8),
        const Text('Importa tu PIVOTES_FINAL.xlsx\ndesde Ajustes para ver tu entrenamiento',
          textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF90A4AE), height: 1.5)),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          icon: const Icon(Icons.upload_file),
          label: const Text('Importar Excel'),
          onPressed: () => context.read<AppProvider>().setTab(4),
        ),
      ]),
    ),
  );

  Widget _restDay(String day) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Text('😴', style: TextStyle(fontSize: 64)),
      const SizedBox(height: 16),
      const Text('Día de descanso', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF546E7A))),
      const SizedBox(height: 8),
      Text('No hay entrenamiento programado para $day.',
        style: const TextStyle(color: Color(0xFF90A4AE))),
      const SizedBox(height: 4),
      const Text('Recupera, estira, hidrata. 🏆',
        style: TextStyle(color: Color(0xFF90A4AE))),
    ]),
  );
}

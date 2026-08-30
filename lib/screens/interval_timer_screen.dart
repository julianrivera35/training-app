import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/interval_timer.dart';
import '../theme/app_theme.dart';

class IntervalTimerScreen extends StatelessWidget {
  const IntervalTimerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.watch<IntervalTimerController>();
    return Scaffold(
      appBar: AppBar(title: const Text('Intervalos'), backgroundColor: AppTheme.navy),
      body: t.active ? const _RunningView() : const _BuilderView(),
    );
  }
}

// ══ Constructor ════════════════════════════════════════════════════
class _BuilderView extends StatefulWidget {
  const _BuilderView();
  @override
  State<_BuilderView> createState() => _BuilderViewState();
}

class _BuilderViewState extends State<_BuilderView> {
  late int work, rest, rounds;

  @override
  void initState() {
    super.initState();
    final t = context.read<IntervalTimerController>();
    work = t.workSec;
    rest = t.restSec;
    rounds = t.rounds;
  }

  @override
  Widget build(BuildContext context) {
    final total = (work + rest) * rounds;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _stepper('🏃 Trabajo (a toda)', _fmt(work), () => setState(() => work = (work - 15).clamp(5, 3600)), () => setState(() => work += 15)),
        const SizedBox(height: 10),
        _stepper('🚶 Descanso (suave)', _fmt(rest), () => setState(() => rest = (rest - 15).clamp(0, 3600)), () => setState(() => rest += 15)),
        const SizedBox(height: 10),
        _stepper('🔁 Repeticiones', '$rounds', () => setState(() => rounds = (rounds - 1).clamp(1, 50)), () => setState(() => rounds += 1)),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.navy.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(children: [
            Text('$rounds × (${_fmt(work)} fuerte + ${_fmt(rest)} suave)',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.navy)),
            const SizedBox(height: 4),
            Text('Total: ${_fmt(total)}', style: const TextStyle(fontSize: 13, color: Color(0xFF546E7A))),
          ]),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 54,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.play_arrow),
            label: const Text('EMPEZAR', style: TextStyle(fontWeight: FontWeight.w800)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.orange, foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: () {
              final t = context.read<IntervalTimerController>();
              t.workSec = work;
              t.restSec = rest;
              t.rounds = rounds;
              t.start();
            },
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Sonará un aviso en cada cambio, aunque tengas la app en segundo plano y música puesta.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: Color(0xFF90A4AE)),
        ),
      ],
    );
  }

  Widget _stepper(String label, String value, VoidCallback onMinus, VoidCallback onPlus) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4)],
    ),
    child: Row(children: [
      Expanded(child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.navy))),
      _roundBtn(Icons.remove, onMinus),
      SizedBox(width: 70, child: Text(value, textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.navy))),
      _roundBtn(Icons.add, onPlus),
    ]),
  );

  Widget _roundBtn(IconData icon, VoidCallback onTap) => InkWell(
    borderRadius: BorderRadius.circular(20),
    onTap: onTap,
    child: Container(
      width: 36, height: 36,
      decoration: BoxDecoration(color: AppTheme.navy.withValues(alpha: 0.08), shape: BoxShape.circle),
      child: Icon(icon, size: 20, color: AppTheme.navy),
    ),
  );

  static String _fmt(int s) {
    final m = s ~/ 60, r = s % 60;
    if (m == 0) return '${r}s';
    if (r == 0) return "$m'";
    return '$m:${r.toString().padLeft(2, '0')}';
  }
}

// ══ En marcha ══════════════════════════════════════════════════════
class _RunningView extends StatelessWidget {
  const _RunningView();

  @override
  Widget build(BuildContext context) {
    final t = context.watch<IntervalTimerController>();
    final p = t.currentPhase;
    final done = t.finished;
    final color = done
        ? AppTheme.green
        : (p?.hard ?? true ? AppTheme.orange : AppTheme.blue);
    final phaseTotal = p?.seconds ?? 1;
    final progress = done ? 1.0 : 1 - (t.remainingInPhase / phaseTotal);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(children: [
        const Spacer(),
        Text(
          done ? '✅ ¡COMPLETADO!' : (p?.hard ?? false ? '🏃 ${p!.label.toUpperCase()}' : '🚶 ${p?.label ?? ''}'),
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color, letterSpacing: 0.5),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        if (!done && p != null)
          Text('Ronda ${p.round} de ${t.rounds}',
            style: const TextStyle(fontSize: 15, color: Color(0xFF90A4AE), fontWeight: FontWeight.w600)),
        const SizedBox(height: 30),
        Stack(alignment: Alignment.center, children: [
          SizedBox(
            width: 230, height: 230,
            child: CircularProgressIndicator(
              value: progress, strokeWidth: 12,
              backgroundColor: const Color(0xFFEEEEEE), color: color),
          ),
          Text(
            done ? '💪' : _mmss(t.remainingInPhase),
            style: TextStyle(fontSize: done ? 64 : 56, fontWeight: FontWeight.w900, color: color,
              fontFeatures: const [FontFeature.tabularFigures()]),
          ),
        ]),
        const SizedBox(height: 24),
        Text('Total restante: ${_mmss(t.remainingTotal)}',
          style: const TextStyle(fontSize: 14, color: Color(0xFF546E7A), fontWeight: FontWeight.w600)),
        const Spacer(),
        SizedBox(
          width: double.infinity, height: 52,
          child: ElevatedButton.icon(
            icon: Icon(done ? Icons.check : Icons.stop),
            label: Text(done ? 'LISTO' : 'DETENER', style: const TextStyle(fontWeight: FontWeight.w800)),
            style: ElevatedButton.styleFrom(
              backgroundColor: done ? AppTheme.green : AppTheme.red, foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: () => context.read<IntervalTimerController>().stop(),
          ),
        ),
      ]),
    );
  }

  static String _mmss(int s) => '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
}

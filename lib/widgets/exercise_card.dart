import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/exercise.dart';
import '../theme/app_theme.dart';
import 'rest_timer_sheet.dart';

class ExerciseCard extends StatefulWidget {
  final Exercise exercise;
  final double? plannedKg;
  final VoidCallback? onToggle;
  final ValueChanged<double?>? onWeightLogged;

  const ExerciseCard({
    super.key,
    required this.exercise,
    this.plannedKg,
    this.onToggle,
    this.onWeightLogged,
  });

  @override
  State<ExerciseCard> createState() => _ExerciseCardState();
}

class _ExerciseCardState extends State<ExerciseCard> {
  bool _expanded = false;
  final _ctrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.exercise.pesoReal != null) {
      _ctrl.text = widget.exercise.pesoReal!.toStringAsFixed(1);
    }
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Color get _catColor => AppTheme.catColor(widget.exercise.bloque);

  @override
  Widget build(BuildContext context) {
    final ex = widget.exercise;
    final isDone = ex.hecho;
    final hasRec = widget.plannedKg != null;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        color: isDone ? const Color(0xFFE8F5E9) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDone ? const Color(0xFF81C784) : Colors.transparent,
          width: 1.5,
        ),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(children: [
        // ── Main tap area ────────────────────────────────────────
        InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Category chip (vertical)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(color: _catColor, borderRadius: BorderRadius.circular(7)),
                child: Text(
                  _shortBloque(ex.bloque),
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.2),
                ),
              ),
              const SizedBox(width: 10),

              // Center: name + stats
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  // Exercise name
                  Text(
                    ex.nombre,
                    style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700,
                      color: isDone ? const Color(0xFF388E3C) : AppTheme.navy,
                      decoration: isDone ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // ─── PESO RECOMENDADO (principal) ─────────────
                  if (hasRec)
                    Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: isDone ? const Color(0xFFDCEDC8) : const Color(0xFFE8EEF7),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.navy.withOpacity(0.2)),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.fitness_center, size: 13, color: AppTheme.navy.withOpacity(0.7)),
                        const SizedBox(width: 5),
                        Text(
                          '${widget.plannedKg!.toStringAsFixed(1)} kg',
                          style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w900,
                            color: isDone ? const Color(0xFF2E7D32) : AppTheme.navy,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'recomendado',
                          style: TextStyle(fontSize: 10, color: AppTheme.navy.withOpacity(0.55), fontWeight: FontWeight.w600),
                        ),
                      ]),
                    )
                  else if (ex.peso.isNotEmpty)
                    // Fallback: peso del Excel
                    Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(ex.peso,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF546E7A))),
                    ),

                  // Series / Reps + Descanso (etiquetas explícitas)
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (ex.series.isNotEmpty)
                        _chip('Series: ${ex.series}', AppTheme.navy, Colors.white),
                      if (ex.reps.isNotEmpty)
                        _chip('Reps: ${ex.reps}', AppTheme.blue, Colors.white),
                      if (ex.descanso.isNotEmpty)
                        GestureDetector(
                          onTap: () => RestTimerSheet.show(context, ex.descanso, ex.nombre),
                          child: _chip('⏱ ${ex.descanso}', const Color(0xFFFFF3E0), const Color(0xFFE65100), border: const Color(0xFFFFCC02)),
                        ),
                    ],
                  ),
                ]),
              ),

              const SizedBox(width: 8),

              // Done button
              GestureDetector(
                onTap: () {
                  final wasNotDone = !ex.hecho;
                  widget.onToggle?.call();
                  if (wasNotDone && ex.descanso.isNotEmpty) {
                    HapticFeedback.mediumImpact();
                    Future.delayed(const Duration(milliseconds: 250), () {
                      if (context.mounted) RestTimerSheet.show(context, ex.descanso, ex.nombre);
                    });
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: isDone ? const Color(0xFF43A047) : const Color(0xFFEEEEEE),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isDone ? Icons.check : Icons.circle_outlined,
                    color: isDone ? Colors.white : Colors.grey[400], size: 20,
                  ),
                ),
              ),
            ]),
          ),
        ),

        // ── Expanded detail ──────────────────────────────────────
        if (_expanded) _expanded$(context, ex),
      ]),
    );
  }

  Widget _chip(String text, Color bg, Color fg, {Color? border}) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(20),
      border: border != null ? Border.all(color: border.withOpacity(0.5)) : null,
    ),
    child: Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg)),
  );

  Widget _expanded$(BuildContext context, Exercise ex) => Container(
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Divider(height: 16, color: Color(0xFFEEEEEE)),

      // Instrucciones
      if (ex.instruccion.isNotEmpty) ...[
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F7FA),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE0E4ED)),
          ),
          child: Text(ex.instruccion,
            style: const TextStyle(fontSize: 13, color: Color(0xFF546E7A), height: 1.55)),
        ),
        const SizedBox(height: 12),
      ],

      // Timer button
      if (ex.descanso.isNotEmpty) ...[
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.timer_outlined, size: 18),
            label: Text('Timer de descanso — ${ex.descanso}'),
            onPressed: () => RestTimerSheet.show(context, ex.descanso, ex.nombre),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFE65100),
              side: const BorderSide(color: Color(0xFFE65100)),
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
        const SizedBox(height: 10),
      ],

      // Peso real
      Row(children: [
        const Text('Peso real usado:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(width: 10),
        SizedBox(
          width: 90,
          child: TextField(
            controller: _ctrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              suffixText: 'kg',
              suffixStyle: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            onChanged: (v) => widget.onWeightLogged?.call(double.tryParse(v)),
          ),
        ),
        if (widget.plannedKg != null) ...[
          const SizedBox(width: 10),
          Text('← vs ${widget.plannedKg!.toStringAsFixed(1)} kg plan',
            style: const TextStyle(fontSize: 11, color: Color(0xFF90A4AE))),
        ],
      ]),
    ]),
  );

  String _shortBloque(String b) {
    final clean = b.replaceAll(RegExp(r'[^\w\sÁÉÍÓÚáéíóúÑñ]'), '').trim();
    final words = clean.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return b.substring(0, b.length.clamp(0, 8)).toUpperCase();
    return words.take(2).map((w) => w.substring(0, w.length.clamp(0, 6))).join('\n').toUpperCase();
  }
}

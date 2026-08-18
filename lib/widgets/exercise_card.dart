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
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          // ── Main row ────────────────────────────────────────────
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category chip
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _catColor,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Text(
                      _shortBloque(ex.bloque),
                      style: const TextStyle(
                        color: Colors.white, fontSize: 10,
                        fontWeight: FontWeight.w800, letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Exercise info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ex.nombre,
                          style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700,
                            color: isDone ? const Color(0xFF388E3C) : AppTheme.navy,
                            decoration: isDone ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        const SizedBox(height: 4),
                        _statsRow(context, ex),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Done button — al marcar, arranca el timer
                  GestureDetector(
                    onTap: () {
                      widget.onToggle?.call();
                      // Arrancar timer si se está marcando (no desmarcando)
                      if (!ex.hecho && ex.descanso.isNotEmpty) {
                        HapticFeedback.mediumImpact();
                        Future.delayed(const Duration(milliseconds: 300), () {
                          if (context.mounted) {
                            RestTimerSheet.show(context, ex.descanso, ex.nombre);
                          }
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
                        color: isDone ? Colors.white : Colors.grey,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Expanded ────────────────────────────────────────────
          if (_expanded) _expandedContent(context, ex),
        ],
      ),
    );
  }

  Widget _statsRow(BuildContext context, Exercise ex) {
    return Wrap(
      spacing: 0,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        // Series × Reps — bien destacado
        if (ex.series.isNotEmpty && ex.reps.isNotEmpty)
          _statChip('${ex.series} × ${ex.reps}', const Color(0xFF1B2F5B), textColor: Colors.white),

        // Peso plan
        if (widget.plannedKg != null)
          _statChip('${widget.plannedKg!.toStringAsFixed(1)} kg', const Color(0xFFE3F2FD), textColor: const Color(0xFF1565C0))
        else if (ex.peso.isNotEmpty)
          _statChip(ex.peso, const Color(0xFFE3F2FD), textColor: const Color(0xFF1565C0)),

        // Descanso — con botón de timer
        if (ex.descanso.isNotEmpty)
          GestureDetector(
            onTap: () => RestTimerSheet.show(context, ex.descanso, ex.nombre),
            child: Container(
              margin: const EdgeInsets.only(left: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFFFCC02).withOpacity(0.6)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.timer_outlined, size: 13, color: Color(0xFFE65100)),
                const SizedBox(width: 3),
                Text(ex.descanso,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFFE65100))),
              ]),
            ),
          ),
      ],
    );
  }

  Widget _statChip(String text, Color bg, {Color textColor = Colors.white}) => Container(
    margin: const EdgeInsets.only(right: 4),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
    child: Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: textColor)),
  );

  Widget _expandedContent(BuildContext context, Exercise ex) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 16, color: Color(0xFFEEEEEE)),

          // Instrucciones
          if (ex.instruccion.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F7FA),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE0E0E0)),
              ),
              child: Text(
                ex.instruccion,
                style: const TextStyle(fontSize: 13, color: Color(0xFF546E7A), height: 1.5),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Timer manual
          if (ex.descanso.isNotEmpty) ...[
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.timer, size: 18),
                label: Text('Iniciar timer de descanso — ${ex.descanso}'),
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
          Row(
            children: [
              const Text('Peso real usado:',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
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
                Text('Plan: ${widget.plannedKg!.toStringAsFixed(1)} kg',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF78909C))),
              ],
            ],
          ),
        ],
      ),
    );
  }

  String _shortBloque(String b) {
    // Quitar emojis, tomar primeras 2 palabras
    final clean = b.replaceAll(RegExp(r'[^\w\sÁÉÍÓÚáéíóúÑñ]'), '').trim();
    final words = clean.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return b.substring(0, b.length.clamp(0, 8)).toUpperCase();
    return words.take(2).map((w) => w.substring(0, w.length.clamp(0, 6))).join(' ').toUpperCase();
  }
}

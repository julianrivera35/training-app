import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/load_exercise.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';

/// Editor de 1RM. El plan de cada ejercicio = 1RM × % de la semana del bloque.
/// Embebido como pestaña dentro de Progreso.
class CargasScreen extends StatelessWidget {
  const CargasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    final ex = p.loadExercises;
    final pct = p.currentPercent;

    if (ex.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.fitness_center_outlined, size: 64, color: Color(0xFFCFD8DC)),
            SizedBox(height: 16),
            Text('Sin ejercicios de carga', style: TextStyle(fontSize: 18, color: Color(0xFF546E7A))),
            SizedBox(height: 8),
            Text('Importa tu Excel (hoja "Cargas y progresión")',
              textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF90A4AE))),
          ]),
        ),
      );
    }

    final groups = <String, List<LoadExercise>>{};
    for (final l in ex) {
      groups.putIfAbsent(l.dia.isEmpty ? 'General' : l.dia, () => []).add(l);
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 100),
      children: [
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.navy.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(children: [
            const Icon(Icons.info_outline, size: 18, color: AppTheme.navy),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Pon tu 1RM de cada ejercicio. El peso planeado = 1RM × % de la semana. '
                'Semana ${p.currentWeek} → bloque sem ${p.blockWeek}${pct != null ? ' (${pct.toInt()}%)' : ''}.',
                style: const TextStyle(fontSize: 12, color: AppTheme.navy, height: 1.3),
              ),
            ),
          ]),
        ),
        for (final entry in groups.entries) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(entry.key.toUpperCase(),
              style: TextStyle(fontSize: 12, color: Colors.grey[700], fontWeight: FontWeight.w800, letterSpacing: 0.5)),
          ),
          ...entry.value.map((l) => _card(context, p, l, pct)),
        ],
      ],
    );
  }

  Widget _card(BuildContext context, AppProvider p, LoadExercise l, double? pct) {
    final rm = p.rmFor(l.nombre);
    final planned = (rm != null && pct != null) ? (rm * pct / 100 / 2.5).round() * 2.5 : null;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4)],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _editRm(context, p, l),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(l.nombre, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.navy)),
                  const SizedBox(height: 3),
                  Text(
                    planned != null ? 'Esta semana: ${_fmt(planned)} kg' : 'Pon tu 1RM para ver el plan',
                    style: TextStyle(fontSize: 12, color: planned != null ? AppTheme.orange : const Color(0xFF90A4AE), fontWeight: FontWeight.w600),
                  ),
                ]),
              ),
              _chip('1RM', rm != null ? '${_fmt(rm)} kg' : '+ poner', rm != null),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _chip(String label, String value, bool filled) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: filled ? AppTheme.navy.withValues(alpha: 0.1) : const Color(0xFFF0F0F0),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppTheme.navy.withValues(alpha: 0.6))),
      Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppTheme.navy)),
    ]),
  );

  Future<void> _editRm(BuildContext context, AppProvider p, LoadExercise l) async {
    final current = p.rmFor(l.nombre);
    final ctrl = TextEditingController(text: current != null ? _fmt(current) : '');
    final result = await showDialog<double?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tu 1RM', style: TextStyle(fontSize: 16)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(l.nombre, style: const TextStyle(fontSize: 13, color: Color(0xFF546E7A))),
          const SizedBox(height: 12),
          TextField(
            controller: ctrl,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
            decoration: InputDecoration(
              hintText: 'Peso máximo (1RM)',
              suffixText: 'kg',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ]),
        actions: [
          if (current != null)
            TextButton(
              onPressed: () => Navigator.pop(ctx, double.nan),
              child: const Text('Borrar', style: TextStyle(color: AppTheme.red)),
            ),
          TextButton(onPressed: () => Navigator.pop(ctx, null), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, double.tryParse(ctrl.text) ?? double.nan),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    if (result == null) return;
    await p.setRM(l.nombre, result.isNaN ? null : result);
  }

  String _fmt(double v) => v == v.truncateToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);
}

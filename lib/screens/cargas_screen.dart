import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/weekly_load.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';

/// Tabla de cargas: peso PLANEADO vs REAL por semana, por ejercicio.
/// Embebida como pestaña dentro de Progreso.
class CargasScreen extends StatefulWidget {
  const CargasScreen({super.key});
  @override
  State<CargasScreen> createState() => _CargasScreenState();
}

class _CargasScreenState extends State<CargasScreen> {
  final Set<String> _expanded = {};

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    final loads = p.loads;
    final week = p.currentWeek;

    if (loads.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.fitness_center_outlined, size: 64, color: Color(0xFFCFD8DC)),
            SizedBox(height: 16),
            Text('Sin cargas cargadas', style: TextStyle(fontSize: 18, color: Color(0xFF546E7A))),
            SizedBox(height: 8),
            Text('Importa tu Excel (hoja "Cargas y progresión")',
              textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF90A4AE))),
          ]),
        ),
      );
    }

    // Group by día preserving order.
    final groups = <String, List<WeeklyLoad>>{};
    for (final l in loads) {
      groups.putIfAbsent(l.dia.isEmpty ? l.grupo : l.dia, () => []).add(l);
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
                'Estás en la semana $week. El plan es el peso estimado; toca "Real" para anotar el que de verdad usaste.',
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
          ...entry.value.map((l) => _loadCard(context, p, l, week)),
        ],
      ],
    );
  }

  Widget _loadCard(BuildContext context, AppProvider p, WeeklyLoad l, int week) {
    final isExp = _expanded.contains(l.nombre);
    final plan = l.planForWeek(week);
    final real = l.realForWeek(week);
    final n = l.planKg.length;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4)],
      ),
      child: Column(children: [
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => setState(() => isExp ? _expanded.remove(l.nombre) : _expanded.add(l.nombre)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(l.nombre, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.navy)),
                  const SizedBox(height: 2),
                  Text('1RM ${_fmt(l.orm)} · ${l.unidad}', style: const TextStyle(fontSize: 11, color: Color(0xFF90A4AE))),
                ]),
              ),
              _weekChip('Plan', plan, AppTheme.navy, null),
              const SizedBox(width: 6),
              _weekChip('Real', real, AppTheme.orange, () => _editReal(context, p, l, week)),
              Icon(isExp ? Icons.expand_less : Icons.expand_more, color: const Color(0xFFBBBBBB)),
            ]),
          ),
        ),
        if (isExp) ...[
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Column(children: [
              for (int w = 1; w <= n; w++) _weekRow(context, p, l, w, w == week),
            ]),
          ),
        ],
      ]),
    );
  }

  Widget _weekRow(BuildContext context, AppProvider p, WeeklyLoad l, int w, bool isCurrent) {
    final plan = l.planForWeek(w);
    final real = l.realForWeek(w);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 8),
      decoration: BoxDecoration(
        color: isCurrent ? AppTheme.navy.withValues(alpha: 0.05) : null,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(children: [
        SizedBox(
          width: 54,
          child: Text('Sem $w', style: TextStyle(
            fontSize: 12, fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
            color: isCurrent ? AppTheme.navy : const Color(0xFF546E7A))),
        ),
        Expanded(
          child: Text('Plan: ${plan != null ? _fmt(plan) : "—"} ${l.unidad.isNotEmpty ? l.unidad.split(" ").first : ""}',
            style: const TextStyle(fontSize: 12, color: Color(0xFF546E7A))),
        ),
        InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => _editReal(context, p, l, w),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: real != null ? AppTheme.orange.withValues(alpha: 0.12) : const Color(0xFFF0F0F0),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              real != null ? 'Real: ${_fmt(real)}' : '+ Real',
              style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w700,
                color: real != null ? AppTheme.orange : const Color(0xFF90A4AE)),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _weekChip(String label, double? value, Color color, VoidCallback? onTap) {
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: value != null || onTap == null ? color.withValues(alpha: 0.12) : const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(label, style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w700, color: color.withValues(alpha: 0.7))),
        Text(value != null ? _fmt(value) : (onTap != null ? '+' : '—'),
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: color)),
      ]),
    );
    if (onTap == null) return chip;
    return InkWell(borderRadius: BorderRadius.circular(8), onTap: onTap, child: chip);
  }

  Future<void> _editReal(BuildContext context, AppProvider p, WeeklyLoad l, int week) async {
    final current = l.realForWeek(week);
    final ctrl = TextEditingController(text: current != null ? _fmt(current) : '');
    final result = await showDialog<double?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Real · Sem $week', style: const TextStyle(fontSize: 16)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(l.nombre, style: const TextStyle(fontSize: 13, color: Color(0xFF546E7A))),
          const SizedBox(height: 12),
          TextField(
            controller: ctrl,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
            decoration: InputDecoration(
              hintText: 'Peso usado',
              suffixText: l.unidad.isNotEmpty ? l.unidad.split(' ').first : 'kg',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ]),
        actions: [
          if (current != null)
            TextButton(
              onPressed: () => Navigator.pop(ctx, double.nan), // sentinel: borrar
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
    if (result == null) return; // cancelado
    if (result.isNaN) {
      await p.setRealLoad(l.nombre, week, null); // borrar / inválido
    } else {
      await p.setRealLoad(l.nombre, week, result);
    }
  }

  String _fmt(double v) => v == v.truncateToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);
}

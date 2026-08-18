import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/progress_entry.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});
  @override State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> with SingleTickerProviderStateMixin {
  late TabController _tab;
  final _pesoCtrl = TextEditingController();
  final _velCtrl  = TextEditingController();
  final _notasCtrl = TextEditingController();
  int _dolorLumbar = 0, _dolorHombro = 0, _dolorRodilla = 0;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    _pesoCtrl.dispose(); _velCtrl.dispose(); _notasCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Progreso'),
        backgroundColor: AppTheme.navy,
        bottom: TabBar(
          controller: _tab,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          indicatorColor: AppTheme.orange,
          tabs: const [
            Tab(text: 'Registrar', icon: Icon(Icons.edit, size: 18)),
            Tab(text: 'Historial', icon: Icon(Icons.show_chart, size: 18)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [_buildForm(), _buildHistory()],
      ),
    );
  }

  // ── Log form ──────────────────────────────────────────────────
  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionLabel('FECHA'),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6)],
          ),
          child: Text(
            DateFormat('EEEE d MMMM yyyy', 'es').format(DateTime.now()),
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.navy),
          ),
        ),
        const SizedBox(height: 16),

        _sectionLabel('PESO CORPORAL'),
        _textField(_pesoCtrl, 'Ej: 91.5', suffix: 'kg'),
        const SizedBox(height: 16),

        _sectionLabel('DOLOR (0 = sin dolor · 10 = máximo)'),
        _painSlider('🔴 Lumbar', _dolorLumbar, (v) => setState(() => _dolorLumbar = v)),
        const SizedBox(height: 8),
        _painSlider('🔵 Hombro D', _dolorHombro, (v) => setState(() => _dolorHombro = v)),
        const SizedBox(height: 8),
        _painSlider('🟡 Rodilla I', _dolorRodilla, (v) => setState(() => _dolorRodilla = v)),
        const SizedBox(height: 16),

        _sectionLabel('VELOCIDAD DE LANZAMIENTO (opcional)'),
        _textField(_velCtrl, 'Ej: 85', suffix: 'km/h'),
        const SizedBox(height: 16),

        _sectionLabel('NOTAS LIBRES'),
        TextField(
          controller: _notasCtrl,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Cómo te sentiste, qué mejoró, qué dolió...',
            filled: true, fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.all(14),
          ),
        ),
        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.save_outlined),
            label: const Text('GUARDAR REGISTRO'),
            onPressed: _save,
          ),
        ),
        const SizedBox(height: 32),
      ]),
    );
  }

  Widget _sectionLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text,
      style: TextStyle(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.w700, letterSpacing: 0.8)),
  );

  Widget _textField(TextEditingController ctrl, String hint, {String? suffix}) => TextField(
    controller: ctrl,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
    decoration: InputDecoration(
      hintText: hint, suffixText: suffix,
      filled: true, fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    ),
  );

  Widget _painSlider(String label, int value, ValueChanged<int> onChanged) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4)],
    ),
    child: Row(children: [
      SizedBox(width: 90, child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
      Expanded(
        child: Slider(
          value: value.toDouble(),
          min: 0, max: 10, divisions: 10,
          activeColor: _painColor(value),
          onChanged: (v) => onChanged(v.toInt()),
        ),
      ),
      SizedBox(
        width: 28,
        child: Text(
          '$value',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _painColor(value)),
        ),
      ),
    ]),
  );

  Color _painColor(int v) {
    if (v <= 2) return AppTheme.green;
    if (v <= 5) return AppTheme.amber;
    if (v <= 7) return AppTheme.orange;
    return AppTheme.red;
  }

  void _save() {
    final p = context.read<AppProvider>();
    final entry = ProgressEntry(
      fecha: DateTime.now(),
      peso: double.tryParse(_pesoCtrl.text),
      dolorLumbar: _dolorLumbar,
      dolorHombro: _dolorHombro,
      dolorRodilla: _dolorRodilla,
      velocidadLanzamiento: double.tryParse(_velCtrl.text),
      notas: _notasCtrl.text.trim(),
    );
    p.addProgress(entry);
    _pesoCtrl.clear(); _velCtrl.clear(); _notasCtrl.clear();
    setState(() { _dolorLumbar = 0; _dolorHombro = 0; _dolorRodilla = 0; });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ Registro guardado'), backgroundColor: AppTheme.green),
    );
    _tab.animateTo(1);
  }

  // ── History ───────────────────────────────────────────────────
  Widget _buildHistory() {
    final p = context.watch<AppProvider>();
    if (p.progress.isEmpty) {
      return const Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.bar_chart_outlined, size: 64, color: Color(0xFFCFD8DC)),
          SizedBox(height: 16),
          Text('Sin registros todavía', style: TextStyle(fontSize: 18, color: Color(0xFF546E7A))),
          SizedBox(height: 8),
          Text('Completa tu primer registro\nen la pestaña Registrar',
            textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF90A4AE))),
        ]),
      );
    }

    final weightData = p.progress
        .where((e) => e.peso != null)
        .toList()
        .reversed
        .toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (weightData.length >= 2) ...[
          _sectionLabel('EVOLUCIÓN DE PESO'),
          _weightChart(weightData),
          const SizedBox(height: 20),
        ],
        _sectionLabel('REGISTROS (${p.progress.length})'),
        ...p.progress.asMap().entries.map((e) => _historyCard(e.value, e.key, p)),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _weightChart(List<ProgressEntry> entries) {
    final spots = entries.asMap().entries.map((e) =>
        FlSpot(e.key.toDouble(), e.value.peso!)).toList();

    return Container(
      height: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
      ),
      child: LineChart(LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(
            showTitles: true, reservedSize: 38,
            getTitlesWidget: (v, _) => Text('${v.toInt()} kg',
              style: const TextStyle(fontSize: 10, color: Color(0xFF90A4AE))),
          )),
          bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true, curveSmoothness: 0.3,
            color: AppTheme.navy, barWidth: 2.5,
            belowBarData: BarAreaData(
              show: true, color: AppTheme.navy.withOpacity(0.08)),
            dotData: FlDotData(getDotPainter: (s, _, __, ___) =>
                FlDotCirclePainter(radius: 4, color: AppTheme.navy, strokeWidth: 0)),
          ),
        ],
      )),
    );
  }

  Widget _historyCard(ProgressEntry e, int idx, AppProvider p) {
    final fmt = DateFormat('EEE d MMM', 'es');
    return Dismissible(
      key: Key('${e.fecha.toIso8601String()}-$idx'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(color: AppTheme.red, borderRadius: BorderRadius.circular(12)),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) => p.deleteProgress(idx),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4)],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(fmt.format(e.fecha),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.navy)),
            const Spacer(),
            if (e.peso != null)
              Text('${e.peso!.toStringAsFixed(1)} kg',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.navy)),
          ]),
          if (e.dolorLumbar != null || e.dolorHombro != null || e.dolorRodilla != null) ...[
            const SizedBox(height: 6),
            Wrap(spacing: 6, children: [
              if (e.dolorLumbar != null) _painBadge('L: ${e.dolorLumbar}', e.dolorLumbar!),
              if (e.dolorHombro != null) _painBadge('H: ${e.dolorHombro}', e.dolorHombro!),
              if (e.dolorRodilla != null) _painBadge('R: ${e.dolorRodilla}', e.dolorRodilla!),
            ]),
          ],
          if (e.notas.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(e.notas, style: const TextStyle(fontSize: 12, color: Color(0xFF78909C)), maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
        ]),
      ),
    );
  }

  Widget _painBadge(String text, int val) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: _painColor(val).withOpacity(0.15),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _painColor(val))),
  );
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../services/pdf_exporter.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes'), backgroundColor: AppTheme.navy),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          // ── Import ──────────────────────────────────────────────
          _section('PLAN DE ENTRENAMIENTO'),
          _tile(
            icon: Icons.upload_file,
            iconColor: AppTheme.navy,
            title: 'Importar PIVOTES_FINAL.xlsx',
            subtitle: p.lastImport != null
                ? 'Último: ${DateFormat('d MMM yyyy, HH:mm', 'es').format(DateTime.parse(p.lastImport!))}'
                : 'Sin plan cargado',
            onTap: () => _import(context, p),
            trailing: p.importStatus == ImportStatus.loading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : p.hasPlan
                    ? const Icon(Icons.check_circle, color: Color(0xFF43A047))
                    : const Icon(Icons.arrow_forward_ios, size: 16),
          ),

          if (p.importStatus == ImportStatus.error)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppTheme.red.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Text('Error: ${p.importError}',
                  style: const TextStyle(fontSize: 12, color: AppTheme.red)),
              ),
            ),

          if (p.importStatus == ImportStatus.success)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppTheme.green.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Text('✅ ${p.days.length} días · ${p.loads.length} ejercicios con cargas',
                  style: const TextStyle(fontSize: 12, color: AppTheme.green)),
              ),
            ),

          const SizedBox(height: 8),

          // ── Current week ────────────────────────────────────────
          _section('SEMANA ACTUAL'),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6)],
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Semana ${p.currentWeek} de 8',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.navy)),
                  Text(p.currentPhase,
                    style: const TextStyle(fontSize: 13, color: Color(0xFF78909C))),
                ],
              ),
              const SizedBox(height: 12),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 6,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
                ),
                child: Slider(
                  value: p.currentWeek.toDouble(),
                  min: 1, max: 8, divisions: 7,
                  activeColor: AppTheme.navy,
                  onChanged: (v) => p.setWeek(v.toInt()),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(8, (i) => Text('${i+1}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: i + 1 == p.currentWeek ? FontWeight.w800 : FontWeight.w400,
                    color: i + 1 == p.currentWeek ? AppTheme.navy : const Color(0xFFBBBBBB),
                  ))),
              ),
              const SizedBox(height: 6),
              const Text(
                '18 ago     25 ago     1 sep     8 sep     15 sep     22 sep     29 sep     6 oct',
                style: TextStyle(fontSize: 9, color: Color(0xFFBBBBBB)),
                overflow: TextOverflow.ellipsis,
              ),
            ]),
          ),

          const SizedBox(height: 8),

          // ── Export ──────────────────────────────────────────────
          _section('EXPORTAR'),
          _tile(
            icon: Icons.picture_as_pdf_outlined,
            iconColor: const Color(0xFFD32F2F),
            title: 'Exportar progreso en PDF',
            subtitle: '${p.progress.length} registros guardados',
            onTap: () => PdfExporter.exportProgress(p.progress),
          ),

          const SizedBox(height: 8),

          // ── Info ────────────────────────────────────────────────
          _section('PERFIL'),
          _infoCard(p),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _section(String title) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
    child: Text(title, style: TextStyle(fontSize: 11, color: Colors.grey[500], fontWeight: FontWeight.w700, letterSpacing: 0.8)),
  );

  Widget _tile({
    required IconData icon,
    required String title,
    required String subtitle,
    Color iconColor = AppTheme.navy,
    VoidCallback? onTap,
    Widget? trailing,
  }) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6)],
    ),
    child: ListTile(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      leading: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF90A4AE))),
      trailing: trailing ?? const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFFBBBBBB)),
      onTap: onTap,
    ),
  );

  Widget _infoCard(AppProvider p) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF1B2F5B), Color(0xFF1565C0)],
        begin: Alignment.topLeft, end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(14),
    ),
    child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Julian Rivera', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
      SizedBox(height: 4),
      Text('Pivote · Selección Bogotá · 24 años · 91 kg · 1.83m',
        style: TextStyle(color: Colors.white70, fontSize: 12)),
      SizedBox(height: 6),
      Text('Meta: Clasificatorios Octubre 2026 🏆',
        style: TextStyle(color: Colors.white54, fontSize: 11)),
    ]),
  );

  Future<void> _import(BuildContext context, AppProvider p) async {
    await p.importExcel();
    if (!context.mounted) return;
    if (p.importStatus == ImportStatus.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Plan importado: ${p.days.length} días, ${p.loads.length} ejercicios con cargas'),
          backgroundColor: AppTheme.green,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }
}

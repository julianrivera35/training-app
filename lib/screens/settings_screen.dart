import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../services/pdf_exporter.dart';
import '../theme/app_theme.dart';
import 'mercado_screen.dart';

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
                decoration: BoxDecoration(color: AppTheme.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: Text('Error: ${p.importError}',
                  style: const TextStyle(fontSize: 12, color: AppTheme.red)),
              ),
            ),

          if (p.importStatus == ImportStatus.success)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppTheme.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: Text('✅ ${p.days.length} días · ${p.loadExercises.length} ejercicios con cargas',
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
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6)],
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Semana ${p.currentWeek}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.navy)),
                  Text('${p.currentPhase} · bloque ${p.blockWeek}${p.currentPercent != null ? ' (${p.currentPercent!.toInt()}%)' : ''}',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF78909C))),
                ],
              ),
              const SizedBox(height: 4),
              Text('Hoy: ${DateFormat('EEEE d MMM yyyy', 'es').format(DateTime.now())}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF90A4AE))),
              const Divider(height: 20),
              Row(children: [
                const Icon(Icons.event, size: 18, color: AppTheme.navy),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    p.startDate != null
                        ? 'Semana 1 empezó: ${DateFormat('d MMM yyyy', 'es').format(p.startDate!)}'
                        : 'Se fija con tu primer entreno',
                    style: const TextStyle(fontSize: 13, color: AppTheme.navy, fontWeight: FontWeight.w600),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: p.startDate ?? DateTime.now(),
                      firstDate: DateTime(2026, 1, 1),
                      lastDate: DateTime(2028, 1, 1),
                    );
                    if (picked != null) p.setStartDate(picked);
                  },
                  child: const Text('Cambiar'),
                ),
              ]),
            ]),
          ),

          const SizedBox(height: 8),

          // ── Mercado ─────────────────────────────────────────────
          _section('NUTRICIÓN'),
          _tile(
            icon: Icons.shopping_cart_outlined,
            iconColor: const Color(0xFF2E7D32),
            title: 'Lista del mercado',
            subtitle: '${p.shopping.where((s) => s.comprado).length} de ${p.shopping.length} comprados',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const MercadoScreen()),
            ),
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
      borderRadius: BorderRadius.circular(14),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6)],
    ),
    child: Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      leading: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF90A4AE))),
      trailing: trailing ?? const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFFBBBBBB)),
      onTap: onTap,
      ),
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
      Text('Meta: Clasificatorios Marzo 2027 🏆',
        style: TextStyle(color: Colors.white54, fontSize: 11)),
    ]),
  );

  Future<void> _import(BuildContext context, AppProvider p) async {
    await p.importExcel();
    if (!context.mounted) return;
    if (p.importStatus == ImportStatus.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Plan importado: ${p.days.length} días, ${p.loadExercises.length} ejercicios con cargas'),
          backgroundColor: AppTheme.green,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }
}

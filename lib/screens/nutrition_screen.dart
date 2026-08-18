import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';

class NutritionScreen extends StatelessWidget {
  const NutritionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final plan = context.watch<AppProvider>().nutrition;

    return Scaffold(
      appBar: AppBar(title: const Text('Nutrición'), backgroundColor: AppTheme.navy),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          // ── Macros summary ───────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('MACROS DIARIOS',
              style: TextStyle(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.w700, letterSpacing: 1)),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(children: [
              _macroCard('Proteína', plan.proteinaTotal, 'g', const Color(0xFF1565C0)),
              const SizedBox(width: 8),
              _macroCard('Carbos', plan.carbosTotal, 'g', const Color(0xFFE65100)),
              const SizedBox(width: 8),
              _macroCard('Grasas', plan.grasasTotal, 'g', const Color(0xFF2E7D32)),
            ]),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1B2F5B), Color(0xFF1565C0)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.local_fire_department, color: Colors.orange, size: 28),
                  const SizedBox(width: 8),
                  Text(
                    '${plan.caloriasTotal} kcal/día',
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── Meal timing ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('TIMING DE COMIDAS',
              style: TextStyle(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.w700, letterSpacing: 1)),
          ),
          const SizedBox(height: 8),
          ...plan.comidas.map((comida) => _mealCard(comida.momento, comida.descripcion, comida.proteina, comida.carbos, comida.grasas, comida.calorias)),
          const SizedBox(height: 20),

          // ── Supplements ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('SUPLEMENTOS',
              style: TextStyle(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.w700, letterSpacing: 1)),
          ),
          const SizedBox(height: 8),
          ...plan.suplementos.asMap().entries.map((e) => _supCard(e.value)),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _macroCard(String label, int value, String unit, Color color) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(children: [
        Text('$value$unit',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 11, color: color.withOpacity(0.8), fontWeight: FontWeight.w600)),
      ]),
    ),
  );

  Widget _mealCard(String momento, String desc, int prot, int carb, int gras, int kcal) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0,2))],
    ),
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(momento, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF1B2F5B))),
        const SizedBox(height: 6),
        Text(desc, style: const TextStyle(fontSize: 13, color: Color(0xFF546E7A), height: 1.4)),
        const SizedBox(height: 8),
        Row(children: [
          _pill('P: ${prot}g', const Color(0xFF1565C0)),
          const SizedBox(width: 6),
          _pill('C: ${carb}g', const Color(0xFFE65100)),
          const SizedBox(width: 6),
          _pill('G: ${gras}g', const Color(0xFF2E7D32)),
          const Spacer(),
          Text('$kcal kcal', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF546E7A))),
        ]),
      ]),
    ),
  );

  Widget _pill(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
    child: Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
  );

  Widget _supCard(String text) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4)],
    ),
    child: Row(children: [
      const Icon(Icons.medication_outlined, size: 18, color: Color(0xFF6A1B9A)),
      const SizedBox(width: 10),
      Expanded(child: Text(text, style: const TextStyle(fontSize: 13, color: Color(0xFF37474F), height: 1.4))),
    ]),
  );
}

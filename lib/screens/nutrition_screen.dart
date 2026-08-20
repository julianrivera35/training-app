import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/shopping_item.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';

class NutritionScreen extends StatelessWidget {
  const NutritionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Nutrición'),
          backgroundColor: AppTheme.navy,
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white54,
            indicatorColor: AppTheme.orange,
            tabs: [
              Tab(text: 'Plan', icon: Icon(Icons.restaurant_menu, size: 18)),
              Tab(text: 'Mercado', icon: Icon(Icons.shopping_cart_outlined, size: 18)),
            ],
          ),
        ),
        body: const TabBarView(
          children: [_PlanTab(), _MercadoTab()],
        ),
      ),
    );
  }
}

// ══ PLAN ═══════════════════════════════════════════════════════════
class _PlanTab extends StatelessWidget {
  const _PlanTab();

  @override
  Widget build(BuildContext context) {
    final plan = context.watch<AppProvider>().nutrition;

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 12),
      children: [
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
                Text('${plan.caloriasTotal} kcal/día',
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text('TIMING DE COMIDAS',
            style: TextStyle(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.w700, letterSpacing: 1)),
        ),
        const SizedBox(height: 8),
        ...plan.comidas.map((c) => _mealCard(c.momento, c.descripcion, c.proteina, c.carbos, c.grasas, c.calorias)),
        const SizedBox(height: 20),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text('SUPLEMENTOS',
            style: TextStyle(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.w700, letterSpacing: 1)),
        ),
        const SizedBox(height: 8),
        ...plan.suplementos.map((s) => _supCard(s)),
        const SizedBox(height: 100),
      ],
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
        Text('$value$unit', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color)),
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
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 2))],
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

// ══ MERCADO ════════════════════════════════════════════════════════
class _MercadoTab extends StatelessWidget {
  const _MercadoTab();

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    final items = p.shopping;

    if (items.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.shopping_cart_outlined, size: 64, color: Color(0xFFCFD8DC)),
            SizedBox(height: 16),
            Text('Sin lista del mercado', style: TextStyle(fontSize: 18, color: Color(0xFF546E7A))),
            SizedBox(height: 8),
            Text('Importa tu Excel (hoja "Lista del mercado")\npara verla aquí',
              textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF90A4AE))),
          ]),
        ),
      );
    }

    // Group by category preserving order.
    final groups = <String, List<ShoppingItem>>{};
    for (final it in items) {
      groups.putIfAbsent(it.categoria, () => []).add(it);
    }
    final bought = items.where((e) => e.comprado).length;

    return Column(children: [
      // Progress + reset bar
      Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        color: const Color(0xFFF7F9FC),
        child: Row(children: [
          Expanded(
            child: Text('$bought de ${items.length} comprados',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.navy)),
          ),
          TextButton.icon(
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Reiniciar'),
            onPressed: bought == 0 ? null : () => p.resetShopping(),
            style: TextButton.styleFrom(foregroundColor: AppTheme.navy),
          ),
        ]),
      ),
      Expanded(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 100, top: 4),
          children: [
            for (final entry in groups.entries) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                child: Text(entry.key.toUpperCase(),
                  style: TextStyle(fontSize: 12, color: Colors.grey[700], fontWeight: FontWeight.w800, letterSpacing: 0.5)),
              ),
              ...entry.value.map((it) => _itemTile(context, p, it)),
            ],
          ],
        ),
      ),
    ]);
  }

  Widget _itemTile(BuildContext context, AppProvider p, ShoppingItem it) {
    final sub = [it.cantidad, it.frecuencia].where((s) => s.isNotEmpty).join(' · ');
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4)],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => p.toggleShopping(it),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(
                it.comprado ? Icons.check_box : Icons.check_box_outline_blank,
                color: it.comprado ? AppTheme.green : const Color(0xFFBBBBBB),
                size: 24,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(
                    it.nombre,
                    style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600,
                      color: it.comprado ? const Color(0xFF9E9E9E) : const Color(0xFF263238),
                      decoration: it.comprado ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  if (sub.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(sub, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.orange)),
                  ],
                  if (it.notas.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(it.notas, style: const TextStyle(fontSize: 11, color: Color(0xFF90A4AE), height: 1.3)),
                  ],
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

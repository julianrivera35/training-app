import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/shopping_item.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';

/// Lista del mercado — accesible desde Ajustes.
class MercadoScreen extends StatelessWidget {
  const MercadoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    final items = p.shopping;

    return Scaffold(
      appBar: AppBar(title: const Text('Lista del mercado'), backgroundColor: AppTheme.navy),
      body: items.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.shopping_cart_outlined, size: 64, color: Color(0xFFCFD8DC)),
                  SizedBox(height: 16),
                  Text('Sin lista del mercado', style: TextStyle(fontSize: 18, color: Color(0xFF546E7A))),
                  SizedBox(height: 8),
                  Text('Importa tu Excel (hoja "Lista del mercado")',
                    textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF90A4AE))),
                ]),
              ),
            )
          : _list(context, p, items),
    );
  }

  Widget _list(BuildContext context, AppProvider p, List<ShoppingItem> items) {
    final groups = <String, List<ShoppingItem>>{};
    for (final it in items) {
      groups.putIfAbsent(it.categoria, () => []).add(it);
    }
    final bought = items.where((e) => e.comprado).length;

    return Column(children: [
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
          padding: const EdgeInsets.only(bottom: 40, top: 4),
          children: [
            for (final entry in groups.entries) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                child: Text(entry.key.toUpperCase(),
                  style: TextStyle(fontSize: 12, color: Colors.grey[700], fontWeight: FontWeight.w800, letterSpacing: 0.5)),
              ),
              ...entry.value.map((it) => _tile(context, p, it)),
            ],
          ],
        ),
      ),
    ]);
  }

  Widget _tile(BuildContext context, AppProvider p, ShoppingItem it) {
    final sub = [it.cantidad, it.frecuencia].where((s) => s.isNotEmpty).join(' · ');
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
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
          onTap: () => p.toggleShopping(it),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(it.comprado ? Icons.check_box : Icons.check_box_outline_blank,
                color: it.comprado ? AppTheme.green : const Color(0xFFBBBBBB), size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(it.nombre,
                    style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600,
                      color: it.comprado ? const Color(0xFF9E9E9E) : const Color(0xFF263238),
                      decoration: it.comprado ? TextDecoration.lineThrough : null,
                    )),
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

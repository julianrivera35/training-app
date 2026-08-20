import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/rest_timer.dart';
import '../theme/app_theme.dart';

class RestTimerSheet extends StatelessWidget {
  const RestTimerSheet({super.key});

  /// Starts a new rest timer and opens the sheet.
  static void show(BuildContext context, String descanso, String exerciseName) {
    final secs = _parse(descanso);
    if (secs <= 0) return;
    context.read<RestTimerController>().start(secs, exerciseName);
    showSheet(context);
  }

  /// Opens the sheet for the already-running timer (from the mini bar).
  static void showSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isDismissible: true,      // cerrar la hoja NO detiene el timer
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const RestTimerSheet(),
    );
  }

  static int _parse(String s) {
    s = s.toLowerCase().trim();
    final minM = RegExp(r'(\d+(?:\.\d+)?)\s*min').firstMatch(s);
    if (minM != null) return (double.parse(minM.group(1)!) * 60).toInt();
    final colM = RegExp(r'(\d+):(\d{2})').firstMatch(s);
    if (colM != null) return int.parse(colM.group(1)!) * 60 + int.parse(colM.group(2)!);
    final segM = RegExp(r'(\d+)\s*(seg|s\b)').firstMatch(s);
    if (segM != null) return int.parse(segM.group(1)!);
    final numM = RegExp(r'(\d+)').firstMatch(s);
    if (numM != null) {
      final n = int.parse(numM.group(1)!);
      return n < 15 ? n * 60 : n;
    }
    return 90;
  }

  static String fmtTime(int secs) {
    final m = secs ~/ 60;
    final s = secs % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  static String _fmtTotal(int secs) {
    final m = secs ~/ 60;
    final s = secs % 60;
    if (m == 0) return '${s}s';
    if (s == 0) return '${m}min';
    return '${m}m ${s}s';
  }

  static Color color(RestTimerController t) {
    if (t.finished) return AppTheme.green;
    if (t.remaining <= 10) return AppTheme.red;
    if (t.remaining <= 30) return AppTheme.orange;
    return AppTheme.navy;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<RestTimerController>();

    // Si el timer se detuvo (p. ej. desde la barra), cerrar la hoja.
    if (!t.active) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (Navigator.of(context).canPop()) Navigator.of(context).pop();
      });
    }

    final c = color(t);
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 24, offset: const Offset(0, -4))],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4,
            decoration: BoxDecoration(color: const Color(0xFFDDDDDD), borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),

          Text(
            t.finished ? '✅  ¡Listo! A la siguiente' : '💤  DESCANSO',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: c, letterSpacing: 1),
          ),
          const SizedBox(height: 2),
          Text(t.exercise,
            style: const TextStyle(fontSize: 12, color: Color(0xFF90A4AE)),
            maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 22),

          Stack(alignment: Alignment.center, children: [
            SizedBox(
              width: 170, height: 170,
              child: CircularProgressIndicator(
                value: t.progress, strokeWidth: 10,
                backgroundColor: const Color(0xFFEEEEEE),
                color: c,
              ),
            ),
            Column(mainAxisSize: MainAxisSize.min, children: [
              Text(
                t.finished ? '💪' : fmtTime(t.remaining),
                style: TextStyle(
                  fontSize: t.finished ? 52 : 44,
                  fontWeight: FontWeight.w900,
                  color: c,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              if (!t.finished)
                Text('de ${_fmtTotal(t.total)}',
                  style: const TextStyle(fontSize: 12, color: Color(0xFFAAAAAA))),
            ]),
          ]),
          const SizedBox(height: 24),

          if (t.finished)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.check, size: 18),
                label: const Text('¡Vamos!'),
                onPressed: () => context.read<RestTimerController>().stop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.green, foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            )
          else ...[
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Reiniciar'),
                  onPressed: () => context.read<RestTimerController>().reset(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.navy,
                    side: const BorderSide(color: AppTheme.navy),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.keyboard_arrow_down, size: 20),
                  label: const Text('Minimizar'),
                  onPressed: () => Navigator.pop(context), // sigue corriendo
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.navy, foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => context.read<RestTimerController>().stop(),
              child: const Text('Saltar descanso', style: TextStyle(color: Color(0xFF90A4AE))),
            ),
          ],
        ]),
      ),
    );
  }
}

/// Persistent bar shown above the bottom navigation while a rest timer runs.
/// Tap to reopen the full sheet; the ✕ stops it.
class RestMiniBar extends StatelessWidget {
  const RestMiniBar({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.watch<RestTimerController>();
    if (!t.active) return const SizedBox.shrink();

    final c = RestTimerSheet.color(t);
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: () => RestTimerSheet.showSheet(context),
        child: Container(
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
          ),
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
          child: Row(children: [
            Icon(t.finished ? Icons.check_circle : Icons.timer_outlined, color: c, size: 22),
            const SizedBox(width: 10),
            SizedBox(
              width: 54,
              child: Text(
                t.finished ? '¡Listo!' : RestTimerSheet.fmtTime(t.remaining),
                style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w900, color: c,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            Expanded(
              child: Text(
                t.finished ? 'Toca para continuar' : 'Descanso · ${t.exercise}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF90A4AE)),
                maxLines: 1, overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 20, color: Color(0xFF90A4AE)),
              onPressed: () => context.read<RestTimerController>().stop(),
            ),
          ]),
        ),
      ),
    );
  }
}

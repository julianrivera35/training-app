import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

class RestTimerSheet extends StatefulWidget {
  final int totalSeconds;
  final String exerciseName;

  const RestTimerSheet({super.key, required this.totalSeconds, required this.exerciseName});

  static void show(BuildContext context, String descanso, String exerciseName) {
    final secs = _parse(descanso);
    if (secs <= 0) return;
    showModalBottomSheet(
      context: context,
      isDismissible: true,
      isScrollControlled: true,
      useSafeArea: true,          // ← respeta Dynamic Island y home indicator
      backgroundColor: Colors.transparent,
      builder: (_) => RestTimerSheet(totalSeconds: secs, exerciseName: exerciseName),
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

  @override
  State<RestTimerSheet> createState() => _RestTimerSheetState();
}

class _RestTimerSheetState extends State<RestTimerSheet>
    with SingleTickerProviderStateMixin {
  late int _remaining;
  Timer? _timer;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _remaining = widget.totalSeconds;
    _start();
  }

  void _start() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_remaining > 0) {
          _remaining--;
          if (_remaining <= 3 && _remaining > 0) HapticFeedback.lightImpact();
        } else {
          _done = true;
          _timer?.cancel();
          HapticFeedback.heavyImpact();
          Future.delayed(const Duration(milliseconds: 400), () => HapticFeedback.heavyImpact());
        }
      });
    });
  }

  void _reset() {
    _timer?.cancel();
    setState(() { _remaining = widget.totalSeconds; _done = false; });
    _start();
  }

  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

  String get _timeStr {
    final m = _remaining ~/ 60;
    final s = _remaining % 60;
    return '${m.toString().padLeft(1)}:${s.toString().padLeft(2, '0')}';
  }

  double get _progress => widget.totalSeconds > 0 ? _remaining / widget.totalSeconds : 0;

  Color get _color {
    if (_done) return AppTheme.green;
    if (_remaining <= 10) return AppTheme.red;
    if (_remaining <= 30) return AppTheme.orange;
    return AppTheme.navy;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 24, offset: const Offset(0, -4))],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [

          // Handle
          Container(width: 40, height: 4,
            decoration: BoxDecoration(color: const Color(0xFFDDDDDD), borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),

          // Estado
          Text(
            _done ? '✅  ¡Listo! A la siguiente' : '💤  DESCANSO',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _color, letterSpacing: 1),
          ),
          const SizedBox(height: 2),
          Text(widget.exerciseName,
            style: const TextStyle(fontSize: 12, color: Color(0xFF90A4AE)),
            maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 22),

          // Círculo de countdown
          Stack(alignment: Alignment.center, children: [
            SizedBox(
              width: 170, height: 170,
              child: CircularProgressIndicator(
                value: _progress, strokeWidth: 10,
                backgroundColor: const Color(0xFFEEEEEE),
                color: _color,
              ),
            ),
            Column(mainAxisSize: MainAxisSize.min, children: [
              Text(
                _done ? '💪' : _timeStr,
                style: TextStyle(
                  fontSize: _done ? 52 : 44,
                  fontWeight: FontWeight.w900,
                  color: _color,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              if (!_done)
                Text(
                  'de ${_fmt(widget.totalSeconds)}',
                  style: const TextStyle(fontSize: 12, color: Color(0xFFAAAAAA)),
                ),
            ]),
          ]),
          const SizedBox(height: 24),

          // Botones
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Reiniciar'),
                onPressed: _reset,
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
                icon: Icon(_done ? Icons.check : Icons.skip_next, size: 18),
                label: Text(_done ? '¡Vamos!' : 'Saltar'),
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _done ? AppTheme.green : AppTheme.navy,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ]),
        ]),
      ),
    );
  }

  String _fmt(int secs) {
    final m = secs ~/ 60; final s = secs % 60;
    if (m == 0) return '${s}s';
    if (s == 0) return '${m}min';
    return '${m}m ${s}s';
  }
}

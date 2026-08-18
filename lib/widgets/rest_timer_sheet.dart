import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

class RestTimerSheet extends StatefulWidget {
  final int totalSeconds;
  final String exerciseName;

  const RestTimerSheet({
    super.key,
    required this.totalSeconds,
    required this.exerciseName,
  });

  static void show(BuildContext context, String descanso, String exerciseName) {
    final secs = _parse(descanso);
    if (secs <= 0) return;
    showModalBottomSheet(
      context: context,
      isDismissible: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RestTimerSheet(totalSeconds: secs, exerciseName: exerciseName),
    );
  }

  static int _parse(String s) {
    s = s.toLowerCase().trim();
    // "X min" / "X minutos"
    final minM = RegExp(r'(\d+(?:\.\d+)?)\s*min').firstMatch(s);
    if (minM != null) return (double.parse(minM.group(1)!) * 60).toInt();
    // "X:YY"
    final colM = RegExp(r'(\d+):(\d{2})').firstMatch(s);
    if (colM != null) return int.parse(colM.group(1)!) * 60 + int.parse(colM.group(2)!);
    // "X seg" / "X s"
    final segM = RegExp(r'(\d+)\s*(seg|s\b)').firstMatch(s);
    if (segM != null) return int.parse(segM.group(1)!);
    // plain number
    final numM = RegExp(r'(\d+)').firstMatch(s);
    if (numM != null) {
      final n = int.parse(numM.group(1)!);
      return n < 15 ? n * 60 : n; // <15 → minutos, else segundos
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
  late AnimationController _pulse;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _remaining = widget.totalSeconds;
    _pulse = AnimationController(vsync: this, duration: const Duration(seconds: 1))
      ..repeat(reverse: true);
    _start();
  }

  void _start() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_remaining > 0) {
          _remaining--;
          if (_remaining <= 3) HapticFeedback.lightImpact();
        } else {
          _done = true;
          _timer?.cancel();
          HapticFeedback.heavyImpact();
          Future.delayed(const Duration(milliseconds: 300), () {
            HapticFeedback.heavyImpact();
          });
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  String get _timeStr {
    final m = _remaining ~/ 60;
    final s = _remaining % 60;
    return '${m.toString().padLeft(1, '0')}:${s.toString().padLeft(2, '0')}';
  }

  double get _progress => widget.totalSeconds > 0
      ? _remaining / widget.totalSeconds
      : 0;

  @override
  Widget build(BuildContext context) {
    final color = _done
        ? AppTheme.green
        : _remaining <= 10
            ? AppTheme.red
            : AppTheme.navy;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 20, offset: const Offset(0, -4)),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Handle
        Container(width: 40, height: 4,
          decoration: BoxDecoration(color: const Color(0xFFDDDDDD), borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 20),

        // Label
        Text(
          _done ? '✅ ¡Listo! Siguiente ejercicio' : '💤 DESCANSO',
          style: TextStyle(
            fontSize: 13, fontWeight: FontWeight.w800,
            color: color, letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          widget.exerciseName,
          style: const TextStyle(fontSize: 12, color: Color(0xFF90A4AE)),
          maxLines: 1, overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 24),

        // Circular progress + time
        Stack(alignment: Alignment.center, children: [
          SizedBox(
            width: 160, height: 160,
            child: CircularProgressIndicator(
              value: _progress,
              strokeWidth: 10,
              backgroundColor: const Color(0xFFEEEEEE),
              color: color,
            ),
          ),
          Column(mainAxisSize: MainAxisSize.min, children: [
            Text(
              _done ? '💪' : _timeStr,
              style: TextStyle(
                fontSize: _done ? 48 : 42,
                fontWeight: FontWeight.w900,
                color: color,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            if (!_done)
              Text(
                'de ${_fmtTotal(widget.totalSeconds)}',
                style: const TextStyle(fontSize: 12, color: Color(0xFFAAAAAA)),
              ),
          ]),
        ]),

        const SizedBox(height: 24),

        // Buttons
        Row(children: [
          Expanded(
            child: OutlinedButton.icon(
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Reiniciar'),
              onPressed: () {
                _timer?.cancel();
                setState(() { _remaining = widget.totalSeconds; _done = false; });
                _start();
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.navy,
                side: const BorderSide(color: AppTheme.navy),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              icon: Icon(_done ? Icons.check : Icons.close, size: 18),
              label: Text(_done ? '¡Vamos!' : 'Saltar'),
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: _done ? AppTheme.green : AppTheme.navy,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ]),
        const SizedBox(height: 8),
      ]),
    );
  }

  String _fmtTotal(int secs) {
    final m = secs ~/ 60;
    final s = secs % 60;
    if (m == 0) return '${s}s';
    if (s == 0) return '${m}min';
    return '${m}min ${s}s';
  }
}

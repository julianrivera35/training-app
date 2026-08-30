import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../services/audio_service.dart';

/// Una fase concreta de la secuencia de intervalos.
class IntervalPhase {
  final String label;   // "A TODA" / "Trote suave"
  final bool hard;      // true = trabajo, false = descanso/suave
  final int seconds;
  final int round;      // 1..rounds
  final int startOffset; // segundos desde el inicio
  const IntervalPhase(this.label, this.hard, this.seconds, this.round, this.startOffset);
}

/// Timer de intervalos: un grupo (trabajo + descanso) que se repite N veces.
/// Suena en cada cambio vía notificaciones locales (funcionan en segundo
/// plano y por encima de la música). Basado en timestamp, así que sigue
/// exacto tras minimizar/bloquear.
class IntervalTimerController extends ChangeNotifier {
  // Config (valores por defecto = cambios de velocidad: 1' fuerte / 2' suave x6)
  int workSec = 60;
  int restSec = 120;
  int rounds = 6;
  String workLabel = 'A TODA';
  String restLabel = 'Trote suave';

  DateTime? _start;
  Timer? _ticker;
  bool _finished = false;
  int _lastPhaseIndex = -1;
  List<IntervalPhase> _phases = const [];

  bool get active => _start != null;
  bool get finished => _finished;
  List<IntervalPhase> get phases => _phases;

  int get totalSeconds => _phases.isEmpty
      ? 0
      : _phases.last.startOffset + _phases.last.seconds;

  int get elapsed {
    if (_start == null) return 0;
    final e = DateTime.now().difference(_start!).inSeconds;
    return e < 0 ? 0 : e;
  }

  int get remainingTotal => (totalSeconds - elapsed).clamp(0, totalSeconds);

  int get currentIndex {
    if (_phases.isEmpty) return -1;
    final e = elapsed;
    for (int i = 0; i < _phases.length; i++) {
      final p = _phases[i];
      if (e < p.startOffset + p.seconds) return i;
    }
    return _phases.length - 1;
  }

  IntervalPhase? get currentPhase {
    final i = currentIndex;
    return (i >= 0 && i < _phases.length) ? _phases[i] : null;
  }

  int get remainingInPhase {
    final p = currentPhase;
    if (p == null) return 0;
    final r = (p.startOffset + p.seconds) - elapsed;
    return r < 0 ? 0 : r;
  }

  List<IntervalPhase> _build() {
    final list = <IntervalPhase>[];
    int offset = 0;
    for (int r = 1; r <= rounds; r++) {
      list.add(IntervalPhase(workLabel, true, workSec, r, offset));
      offset += workSec;
      list.add(IntervalPhase(restLabel, false, restSec, r, offset));
      offset += restSec;
    }
    return list;
  }

  Future<void> start() async {
    if (workSec <= 0 || rounds <= 0) return;
    _phases = _build();
    _start = DateTime.now();
    _finished = false;
    _lastPhaseIndex = 0;
    HapticFeedback.heavyImpact();

    // Audio de silencio en loop → mantiene la app viva en segundo plano
    // para que el ticker siga sonando con la pantalla bloqueada.
    AudioService.startKeepAlive();
    AudioService.beep(times: 2); // arranque

    _startTicker();
    notifyListeners();
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_start == null) {
        _ticker?.cancel();
        return;
      }
      // Beep + haptic al cruzar a una nueva fase (2 beeps para trabajo, 1 para descanso).
      final idx = currentIndex;
      if (idx != _lastPhaseIndex) {
        _lastPhaseIndex = idx;
        HapticFeedback.heavyImpact();
        final p = currentPhase;
        AudioService.beep(times: (p?.hard ?? false) ? 2 : 1);
      }
      if (elapsed >= totalSeconds && !_finished) {
        _finished = true;
        HapticFeedback.heavyImpact();
        AudioService.beep(times: 3); // final
        AudioService.stopKeepAlive();
        _ticker?.cancel();
      }
      notifyListeners();
    });
  }

  Future<void> stop() async {
    _ticker?.cancel();
    _ticker = null;
    _start = null;
    _finished = false;
    _lastPhaseIndex = -1;
    await AudioService.stopKeepAlive();
    notifyListeners();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}

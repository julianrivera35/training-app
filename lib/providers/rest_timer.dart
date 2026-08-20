import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../services/notification_service.dart';

/// Rest timer state that lives above the widget tree so it keeps running
/// while you navigate or minimize the sheet. It is driven by an absolute
/// end-time, so it stays accurate even after the app is backgrounded (iOS
/// pauses the ticker; on resume the remaining time is recomputed). A local
/// notification covers the case where the app is fully closed.
class RestTimerController extends ChangeNotifier {
  DateTime? _endTime;
  int _total = 0;
  String _exercise = '';
  Timer? _ticker;
  bool _finished = false;

  bool get active => _endTime != null;
  bool get finished => _finished;
  String get exercise => _exercise;
  int get total => _total;

  int get remaining {
    if (_endTime == null) return 0;
    final r = _endTime!.difference(DateTime.now()).inSeconds;
    return r < 0 ? 0 : r;
  }

  double get progress => _total > 0 ? remaining / _total : 0.0;

  void start(int seconds, String exercise) {
    if (seconds <= 0) return;
    _total = seconds;
    _exercise = exercise;
    _finished = false;
    _endTime = DateTime.now().add(Duration(seconds: seconds));
    NotificationService.scheduleRestEnd(seconds, exercise);
    _startTicker();
    notifyListeners();
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_endTime == null) {
        _ticker?.cancel();
        return;
      }
      final left = remaining;
      if (left <= 3 && left > 0) HapticFeedback.lightImpact();
      if (left <= 0 && !_finished) {
        _finished = true;
        HapticFeedback.heavyImpact();
        _ticker?.cancel();
      }
      notifyListeners();
    });
  }

  void reset() {
    if (_total <= 0) return;
    start(_total, _exercise);
  }

  void addSeconds(int s) {
    if (_endTime == null) return;
    _endTime = _endTime!.add(Duration(seconds: s));
    _total += s;
    _finished = false;
    NotificationService.cancelRestEnd();
    NotificationService.scheduleRestEnd(remaining, _exercise);
    _startTicker();
    notifyListeners();
  }

  /// Stop and clear the timer (skip / done).
  void stop() {
    _ticker?.cancel();
    _ticker = null;
    _endTime = null;
    _finished = false;
    NotificationService.cancelRestEnd();
    notifyListeners();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}

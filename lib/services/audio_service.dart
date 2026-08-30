import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Reproduce beeps reales (categoría playback → suenan por encima de la
/// música y aunque el iPhone esté en silencio) y mantiene un audio de
/// silencio en loop para que la app siga viva en segundo plano y el ticker
/// del timer pueda sonar con la pantalla bloqueada / en el bolsillo.
class AudioService {
  static final AudioPlayer _beep = AudioPlayer(playerId: 'interval_beep');
  static final AudioPlayer _keepAlive = AudioPlayer(playerId: 'interval_keepalive');
  static bool _configured = false;

  static Future<void> _configure() async {
    if (_configured) return;
    try {
      await AudioPlayer.global.setAudioContext(
        AudioContext(
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.playback,
            options: const {AVAudioSessionOptions.mixWithOthers},
          ),
        ),
      );
      await _beep.setReleaseMode(ReleaseMode.stop);
      await _keepAlive.setReleaseMode(ReleaseMode.loop);
      _configured = true;
    } catch (e) {
      debugPrint('AudioService.configure failed: $e');
    }
  }

  static Future<void> startKeepAlive() async {
    await _configure();
    try {
      await _keepAlive.play(AssetSource('audio/silence.wav'), volume: 0);
    } catch (e) {
      debugPrint('AudioService.startKeepAlive failed: $e');
    }
  }

  static Future<void> stopKeepAlive() async {
    try {
      await _keepAlive.stop();
    } catch (_) {}
  }

  /// Reproduce [times] beeps seguidos.
  static Future<void> beep({int times = 1}) async {
    await _configure();
    try {
      for (int i = 0; i < times; i++) {
        if (i > 0) await Future.delayed(const Duration(milliseconds: 240));
        await _beep.stop();
        await _beep.play(AssetSource('audio/beep.wav'), volume: 1.0);
      }
    } catch (e) {
      debugPrint('AudioService.beep failed: $e');
    }
  }
}

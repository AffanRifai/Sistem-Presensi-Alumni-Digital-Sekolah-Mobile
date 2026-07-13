import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class WelcomeAudioService {
  WelcomeAudioService._();

  static final AudioPlayer _player = AudioPlayer();
  static final AssetSource _welcomeAudio = AssetSource(
    'voiceover/warmwelcome.wav',
  );

  static Future<void> play() async {
    try {
      await _player.stop();
      await _player.setReleaseMode(ReleaseMode.release);
      await _player.play(_welcomeAudio, volume: 0.8);
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[WelcomeAudio] Gagal memutar audio: $error');
      }
    }
  }
}

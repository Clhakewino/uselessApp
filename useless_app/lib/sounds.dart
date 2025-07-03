import 'package:audioplayers/audioplayers.dart';

class Sounds {
  static final AudioPlayer _player = AudioPlayer();
  static bool _isPlaying = false;

  static Future<void> playBackgroundMusic() async {
    if (_isPlaying) return;
    await _player.setReleaseMode(ReleaseMode.loop);
    await _player.play(AssetSource('sounds/pacefulTheme.mp3'));
    _isPlaying = true;
  }

  static Future<void> stopBackgroundMusic() async {
    await _player.stop();
    _isPlaying = false;
  }

  static Future<void> pauseBackgroundMusic() async {
    await _player.pause();
    _isPlaying = false;
  }

  static Future<void> resumeBackgroundMusic() async {
    if (!_isPlaying) {
      await _player.resume();
      _isPlaying = true;
    }
  }
}



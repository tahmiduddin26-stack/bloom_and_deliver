import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Sound IDs used throughout the game.
enum GameSound {
  /// Looping ambient shop background.
  ambientShop,

  /// Played when a flower is dragged into the workspace.
  flowerDrop,

  /// Played on bouquet submit.
  submit,

  /// Happy jingle on a "great" order result.
  greatOrder,

  /// Soft disappointed tone on a "poor" result.
  poorOrder,

  /// Coin clink — used when earning money or completing a challenge.
  coin,

  /// Light chime for in-game notifications.
  notification,
}

extension _SoundPath on GameSound {
  String get assetPath => switch (this) {
        GameSound.ambientShop => 'audio/ambient_shop.mp3',
        GameSound.flowerDrop => 'audio/flower_drop.mp3',
        GameSound.submit => 'audio/submit.mp3',
        GameSound.greatOrder => 'audio/great_order.mp3',
        GameSound.poorOrder => 'audio/poor_order.mp3',
        GameSound.coin => 'audio/coin.mp3',
        GameSound.notification => 'audio/notification.mp3',
      };
}

/// Singleton audio service. All playback is silently swallowed if the
/// corresponding asset file is missing — the game runs fine without audio.
class AudioService {
  AudioService._();
  static final AudioService instance = AudioService._();

  final AudioPlayer _ambientPlayer = AudioPlayer();

  // Small rotating pool so overlapping effects (e.g. submit + coin) don't
  // cut each other off mid-play.
  final List<AudioPlayer> _sfxPool =
      List.generate(3, (_) => AudioPlayer());
  int _nextSfx = 0;

  bool _muted = false;
  bool get isMuted => _muted;

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Play a one-shot sound effect.
  Future<void> play(GameSound sound) async {
    if (_muted || sound == GameSound.ambientShop) return;
    final player = _sfxPool[_nextSfx];
    _nextSfx = (_nextSfx + 1) % _sfxPool.length;
    try {
      await player.play(AssetSource(sound.assetPath));
    } catch (_) {
      // Missing asset or platform not supported — silent no-op.
    }
  }

  /// Start the ambient background loop. Silently ignored if file is missing.
  Future<void> startAmbient() async {
    if (_muted) return;
    try {
      _ambientPlayer.setReleaseMode(ReleaseMode.loop);
      await _ambientPlayer.play(
        AssetSource(GameSound.ambientShop.assetPath),
      );
    } catch (_) {}
  }

  /// Pause the ambient track (e.g. when opening a modal screen).
  Future<void> pauseAmbient() async {
    try {
      await _ambientPlayer.pause();
    } catch (_) {}
  }

  /// Resume the ambient track.
  Future<void> resumeAmbient() async {
    if (_muted) return;
    try {
      await _ambientPlayer.resume();
    } catch (_) {}
  }

  /// Toggle mute globally. Stops/resumes ambient accordingly.
  Future<void> toggleMute() async {
    _muted = !_muted;
    if (_muted) {
      await pauseAmbient();
    } else {
      await resumeAmbient();
    }
    debugPrint('AudioService: muted=$_muted');
  }

  Future<void> dispose() async {
    await _ambientPlayer.dispose();
    for (final p in _sfxPool) {
      await p.dispose();
    }
  }
}

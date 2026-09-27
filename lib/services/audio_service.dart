import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    GameSound.ambientShop => 'audio/ambient_shop.wav',
    GameSound.flowerDrop => 'audio/flower_drop.wav',
    GameSound.submit => 'audio/submit.wav',
    GameSound.greatOrder => 'audio/great_order.wav',
    GameSound.poorOrder => 'audio/poor_order.wav',
    GameSound.coin => 'audio/coin.wav',
    GameSound.notification => 'audio/notification.wav',
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
  final List<AudioPlayer> _sfxPool = List.generate(3, (_) => AudioPlayer());
  int _nextSfx = 0;
  Future<Set<String>>? _availableAssets;

  Future<bool> _hasSound(GameSound sound) async {
    _availableAssets ??= AssetManifest.loadFromAssetBundle(
      rootBundle,
    ).then((manifest) => manifest.listAssets().toSet());
    return (await _availableAssets!).contains('assets/${sound.assetPath}');
  }

  bool _muted = false;
  bool _ambientStarted = false;
  static const _mutePreferenceKey = 'sound_muted';
  bool get isMuted => _muted;

  Future<void> loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _muted = prefs.getBool(_mutePreferenceKey) ?? false;
    } catch (_) {
      _muted = false;
    }
  }

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Play a one-shot sound effect.
  Future<void> play(GameSound sound) async {
    if (_muted || sound == GameSound.ambientShop) return;
    if (!await _hasSound(sound)) return;
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
    if (!await _hasSound(GameSound.ambientShop)) return;
    try {
      await _ambientPlayer.setReleaseMode(ReleaseMode.loop);
      await _ambientPlayer.play(AssetSource(GameSound.ambientShop.assetPath));
      _ambientStarted = true;
    } catch (_) {}
  }

  /// Pause the ambient track (e.g. when opening a modal screen).
  Future<void> pauseAmbient() async {
    if (!_ambientStarted) return;
    try {
      await _ambientPlayer.pause();
    } catch (_) {}
  }

  /// Resume the ambient track.
  Future<void> resumeAmbient() async {
    if (_muted || !_ambientStarted) return;
    try {
      await _ambientPlayer.resume();
    } catch (_) {}
  }

  /// Persist the player's sound choice and stop/resume the shop loop.
  Future<void> setMuted(bool muted) async {
    if (_muted == muted) return;
    _muted = muted;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_mutePreferenceKey, muted);
    } catch (_) {}
    if (_muted) {
      await pauseAmbient();
    } else if (_ambientStarted) {
      await resumeAmbient();
    } else {
      await startAmbient();
    }
    debugPrint('AudioService: muted=$_muted');
  }

  Future<void> toggleMute() => setMuted(!_muted);

  Future<void> dispose() async {
    await _ambientPlayer.dispose();
    for (final p in _sfxPool) {
      await p.dispose();
    }
  }
}

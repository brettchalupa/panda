import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import 'jellyfin_api.dart';

class AudioPlayerService extends ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();
  Track? _currentTrack;
  Album? _currentAlbum;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  String? _albumArtUrl;

  Track? get currentTrack => _currentTrack;
  Album? get currentAlbum => _currentAlbum;
  bool get isPlaying => _isPlaying;
  Duration get position => _position;
  Duration get duration => _duration;
  String? get albumArtUrl => _albumArtUrl;

  double get progress {
    if (_duration.inMilliseconds == 0) return 0.0;
    return _position.inMilliseconds / _duration.inMilliseconds;
  }

  AudioPlayerService() {
    _audioPlayer.onPlayerStateChanged.listen((state) {
      _isPlaying = state == PlayerState.playing;
      notifyListeners();
    });

    _audioPlayer.onPositionChanged.listen((position) {
      _position = position;
      notifyListeners();
    });

    _audioPlayer.onDurationChanged.listen((duration) {
      _duration = duration;
      notifyListeners();
    });
  }

  Future<void> playTrack(
    Track track,
    Album album,
    String streamUrl,
    String? albumArtUrl,
  ) async {
    await _audioPlayer.play(UrlSource(streamUrl));
    _currentTrack = track;
    _currentAlbum = album;
    _albumArtUrl = albumArtUrl;
    notifyListeners();
  }

  Future<void> togglePlayPause() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.resume();
    }
  }

  Future<void> stop() async {
    await _audioPlayer.stop();
    _currentTrack = null;
    _currentAlbum = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}

import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:audio_service/audio_service.dart';
import 'jellyfin_api.dart';

class AudioPlayerService extends ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();
  AudioHandler? _audioHandler;
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
    _init();

    _audioPlayer.onPlayerStateChanged.listen((state) {
      _isPlaying = state == PlayerState.playing;
      _updatePlaybackState();
      notifyListeners();
    });

    _audioPlayer.onPositionChanged.listen((position) {
      _position = position;
      _updatePlaybackState();
      notifyListeners();
    });

    _audioPlayer.onDurationChanged.listen((duration) {
      _duration = duration;
      notifyListeners();
    });
  }

  Future<void> _init() async {
    _audioHandler = await AudioService.init(
      builder: () => StingrayAudioHandler(this),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.stingray.audio',
        androidNotificationChannelName: 'Stingray',
        androidNotificationOngoing: true,
      ),
    );
  }

  void _updatePlaybackState() {
    if (_audioHandler is StingrayAudioHandler) {
      (_audioHandler as StingrayAudioHandler).updatePlaybackState(
        playing: _isPlaying,
        position: _position,
      );
    }
  }

  void _updateMediaItem() {
    if (_currentTrack != null &&
        _currentAlbum != null &&
        _audioHandler is StingrayAudioHandler) {
      (_audioHandler as StingrayAudioHandler).setMediaItem(
        id: _currentTrack!.id,
        title: _currentTrack!.name,
        album: _currentAlbum!.name,
        artist: _currentAlbum!.artist ?? 'Unknown Artist',
        duration: _duration,
        artUri: _albumArtUrl,
      );
    }
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
    _updateMediaItem();
    _updatePlaybackState();
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
    _updatePlaybackState();
    notifyListeners();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}

/// Audio handler for integrating with system media controls
class StingrayAudioHandler extends BaseAudioHandler {
  final AudioPlayerService _service;

  StingrayAudioHandler(this._service);

  void updatePlaybackState({
    required bool playing,
    required Duration position,
  }) {
    playbackState.add(
      PlaybackState(
        controls: [
          MediaControl.skipToPrevious,
          if (playing) MediaControl.pause else MediaControl.play,
          MediaControl.skipToNext,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
        androidCompactActionIndices: const [0, 1, 2],
        processingState: AudioProcessingState.ready,
        playing: playing,
        updatePosition: position,
        bufferedPosition: position,
        speed: playing ? 1.0 : 0.0,
        queueIndex: 0,
      ),
    );
  }

  void setMediaItem({
    required String id,
    required String title,
    required String album,
    required String artist,
    required Duration duration,
    String? artUri,
  }) {
    mediaItem.add(
      MediaItem(
        id: id,
        album: album,
        title: title,
        artist: artist,
        duration: duration,
        artUri: artUri != null ? Uri.parse(artUri) : null,
      ),
    );
  }

  @override
  Future<void> play() async {
    await _service.togglePlayPause();
  }

  @override
  Future<void> pause() async {
    await _service.togglePlayPause();
  }

  @override
  Future<void> stop() async {
    await _service.stop();
  }
}

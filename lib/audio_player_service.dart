import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:audio_service/audio_service.dart';
import 'jellyfin_api.dart';

class QueueItem {
  final Track track;
  final Album album;
  final String streamUrl;
  final String? albumArtUrl;

  QueueItem({
    required this.track,
    required this.album,
    required this.streamUrl,
    required this.albumArtUrl,
  });
}

class AudioPlayerService extends ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();
  AudioHandler? _audioHandler;
  Track? _currentTrack;
  Album? _currentAlbum;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  String? _albumArtUrl;
  final List<QueueItem> _queue = [];
  int _currentQueueIndex = -1;
  JellyfinApi? _api;
  DateTime? _lastProgressReport;
  bool _hasReportedStart = false;

  Track? get currentTrack => _currentTrack;
  Album? get currentAlbum => _currentAlbum;
  bool get isPlaying => _isPlaying;
  Duration get position => _position;
  Duration get duration => _duration;
  String? get albumArtUrl => _albumArtUrl;
  List<QueueItem> get queue => List.unmodifiable(_queue);
  int get queueIndex => _currentQueueIndex;
  bool get hasNext => _currentQueueIndex < _queue.length - 1;
  bool get hasPrevious => _currentQueueIndex > 0;

  void setApi(JellyfinApi api) {
    _api = api;
  }

  double get progress {
    if (_duration.inMilliseconds == 0) return 0.0;
    return _position.inMilliseconds / _duration.inMilliseconds;
  }

  /// Update the current track's favorite status
  void updateTrackFavoriteStatus(String trackId, bool isFavorite) {
    if (_currentTrack?.id == trackId) {
      _currentTrack = _currentTrack!.copyWith(isFavorite: isFavorite);
      notifyListeners();
    }
    // Also update in queue
    for (var i = 0; i < _queue.length; i++) {
      if (_queue[i].track.id == trackId) {
        _queue[i] = QueueItem(
          track: _queue[i].track.copyWith(isFavorite: isFavorite),
          album: _queue[i].album,
          streamUrl: _queue[i].streamUrl,
          albumArtUrl: _queue[i].albumArtUrl,
        );
      }
    }
  }

  int _durationToTicks(Duration duration) {
    return duration.inMicroseconds * 10; // 1 tick = 100 nanoseconds
  }

  void _reportProgressIfNeeded() {
    if (_api == null || _currentTrack == null) return;

    final now = DateTime.now();
    // Report progress every 10 seconds
    if (_lastProgressReport == null ||
        now.difference(_lastProgressReport!) > const Duration(seconds: 10)) {
      _lastProgressReport = now;
      final positionTicks = _durationToTicks(_position);
      _api!
          .reportPlaybackProgress(
        _currentTrack!.id,
        positionTicks,
        !_isPlaying,
      )
          .catchError((e) {
        // Silently fail - don't interrupt playback
        if (kDebugMode) {
          print('Failed to report playback progress: $e');
        }
      });
    }
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
      _reportProgressIfNeeded();
      notifyListeners();
    });

    _audioPlayer.onDurationChanged.listen((duration) {
      _duration = duration;
      notifyListeners();
    });

    _audioPlayer.onPlayerComplete.listen((_) {
      // Auto-play next track when current track finishes
      if (hasNext) {
        playNext();
      }
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
        hasNext: hasNext,
        hasPrevious: hasPrevious,
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

  /// Internal method to play a track without modifying the queue
  Future<void> _playTrackInternal(
    Track track,
    Album album,
    String streamUrl,
    String? albumArtUrl,
  ) async {
    // Report stop for previous track if any
    if (_currentTrack != null && _api != null) {
      final positionTicks = _durationToTicks(_position);
      _api!.reportPlaybackStopped(_currentTrack!.id, positionTicks).catchError(
        (e) {
          if (kDebugMode) {
            print('Failed to report playback stopped: $e');
          }
        },
      );
    }

    await _audioPlayer.play(UrlSource(streamUrl));
    _currentTrack = track;
    _currentAlbum = album;
    _albumArtUrl = albumArtUrl;
    _hasReportedStart = false;
    _lastProgressReport = null;

    // Report playback start
    if (_api != null) {
      _api!.reportPlaybackStart(track.id, 0).catchError((e) {
        if (kDebugMode) {
          print('Failed to report playback start: $e');
        }
      });
      _hasReportedStart = true;
    }

    _updateMediaItem();
    _updatePlaybackState();
    notifyListeners();
  }

  /// Play a track and optionally set up a queue with remaining tracks
  Future<void> playTrack(
    Track track,
    Album album,
    String streamUrl,
    String? albumArtUrl, {
    List<QueueItem>? queue,
    int queueIndex = 0,
  }) async {
    if (queue != null) {
      _queue.clear();
      _queue.addAll(queue);
      _currentQueueIndex = queueIndex;
    } else {
      _queue.clear();
      _queue.add(
        QueueItem(
          track: track,
          album: album,
          streamUrl: streamUrl,
          albumArtUrl: albumArtUrl,
        ),
      );
      _currentQueueIndex = 0;
    }

    await _playTrackInternal(track, album, streamUrl, albumArtUrl);
  }

  Future<void> playNext() async {
    if (!hasNext) return;
    _currentQueueIndex++;
    final item = _queue[_currentQueueIndex];
    await _playTrackInternal(
      item.track,
      item.album,
      item.streamUrl,
      item.albumArtUrl,
    );
  }

  Future<void> playPrevious() async {
    if (!hasPrevious) return;
    _currentQueueIndex--;
    final item = _queue[_currentQueueIndex];
    await _playTrackInternal(
      item.track,
      item.album,
      item.streamUrl,
      item.albumArtUrl,
    );
  }

  Future<void> skipToQueueIndex(int index) async {
    if (index < 0 || index >= _queue.length) return;
    _currentQueueIndex = index;
    final item = _queue[_currentQueueIndex];
    await _playTrackInternal(
      item.track,
      item.album,
      item.streamUrl,
      item.albumArtUrl,
    );
  }

  Future<void> togglePlayPause() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.resume();
    }
  }

  Future<void> stop() async {
    // Report stop before clearing track
    if (_currentTrack != null && _api != null) {
      final positionTicks = _durationToTicks(_position);
      _api!.reportPlaybackStopped(_currentTrack!.id, positionTicks).catchError(
        (e) {
          if (kDebugMode) {
            print('Failed to report playback stopped: $e');
          }
        },
      );
    }

    await _audioPlayer.stop();
    _currentTrack = null;
    _currentAlbum = null;
    _hasReportedStart = false;
    _lastProgressReport = null;
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
    required bool hasNext,
    required bool hasPrevious,
  }) {
    final controls = <MediaControl>[];
    if (hasPrevious) {
      controls.add(MediaControl.skipToPrevious);
    }
    controls.add(playing ? MediaControl.pause : MediaControl.play);
    if (hasNext) {
      controls.add(MediaControl.skipToNext);
    }

    playbackState.add(
      PlaybackState(
        controls: controls,
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

  @override
  Future<void> skipToNext() async {
    await _service.playNext();
  }

  @override
  Future<void> skipToPrevious() async {
    await _service.playPrevious();
  }
}

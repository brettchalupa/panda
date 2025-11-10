import 'package:flutter_test/flutter_test.dart';
import 'package:panda/audio_player_service.dart';
import 'package:panda/jellyfin_api.dart';

void main() {
  // Note: AudioPlayerService testing requires mocking audioplayers and audio_service
  // which is complex. These tests focus on the data classes.

  group('QueueItem', () {
    test('can be created with required fields', () {
      final album = Album(id: 'album1', name: 'Test Album');
      final track = Track(id: 'track1', name: 'Track 1');

      final item = QueueItem(
        track: track,
        album: album,
        streamUrl: 'http://test/stream',
        albumArtUrl: 'http://test/art',
      );

      expect(item.track, track);
      expect(item.album, album);
      expect(item.streamUrl, 'http://test/stream');
      expect(item.albumArtUrl, 'http://test/art');
    });

    test('albumArtUrl can be null', () {
      final album = Album(id: 'album1', name: 'Test Album');
      final track = Track(id: 'track1', name: 'Track 1');

      final item = QueueItem(
        track: track,
        album: album,
        streamUrl: 'http://test/stream',
        albumArtUrl: null,
      );

      expect(item.albumArtUrl, isNull);
    });
  });
}

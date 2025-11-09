import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'audio_player_service.dart';
import 'jellyfin_api.dart';

class NowPlayingScreen extends StatefulWidget {
  final JellyfinApi api;

  const NowPlayingScreen({super.key, required this.api});

  @override
  State<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends State<NowPlayingScreen> {
  Future<void> _toggleFavorite(
    Track track,
    AudioPlayerService playerService,
  ) async {
    try {
      if (track.isFavorite) {
        await widget.api.unmarkFavorite(track.id);
        playerService.updateTrackFavoriteStatus(track.id, false);
      } else {
        await widget.api.markFavorite(track.id);
        playerService.updateTrackFavoriteStatus(track.id, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update favorite: $e')),
        );
      }
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final playerService = Provider.of<AudioPlayerService>(context);

    if (playerService.currentTrack == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Now Playing'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: const Center(child: Text('No track playing')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Now Playing'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 700;

          if (isWide) {
            // Two-column layout for wider screens
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left column: Album art and controls
                SizedBox(
                  width: 400,
                  child: _buildPlayerSection(context, playerService),
                ),
                const VerticalDivider(width: 1),
                // Right column: Queue
                Expanded(child: _buildQueueSection(context, playerService)),
              ],
            );
          } else {
            // Stacked layout for narrow screens
            return Column(
              children: [
                _buildPlayerSection(context, playerService),
                const Divider(height: 1),
                Expanded(child: _buildQueueSection(context, playerService)),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildPlayerSection(
    BuildContext context,
    AudioPlayerService playerService,
  ) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Album art
            if (playerService.albumArtUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: playerService.albumArtUrl!,
                  width: 300,
                  height: 300,
                  fit: BoxFit.cover,
                  placeholder: (context, url) =>
                      const Icon(Icons.album, size: 300),
                  errorWidget: (context, url, error) =>
                      const Icon(Icons.album, size: 300),
                ),
              )
            else
              const Icon(Icons.album, size: 300),
            const SizedBox(height: 32),
            // Track name
            Text(
              playerService.currentTrack!.name,
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            // Artist
            Text(
              playerService.currentAlbum?.artist ?? 'Unknown Artist',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            // Album
            Text(
              playerService.currentAlbum?.name ?? '',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            // Progress bar
            Column(
              children: [
                LinearProgressIndicator(
                  value: playerService.progress,
                  minHeight: 4,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDuration(playerService.position),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      _formatDuration(playerService.duration),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Playback controls
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.skip_previous),
                  iconSize: 48,
                  onPressed: playerService.hasPrevious
                      ? playerService.playPrevious
                      : null,
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: Icon(
                    playerService.isPlaying
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_filled,
                  ),
                  iconSize: 72,
                  onPressed: playerService.togglePlayPause,
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.skip_next),
                  iconSize: 48,
                  onPressed: playerService.hasNext
                      ? playerService.playNext
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Favorite button
            IconButton(
              icon: Icon(
                playerService.currentTrack!.isFavorite
                    ? Icons.favorite
                    : Icons.favorite_border,
                color: playerService.currentTrack!.isFavorite
                    ? Colors.red
                    : null,
              ),
              iconSize: 32,
              onPressed: () =>
                  _toggleFavorite(playerService.currentTrack!, playerService),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQueueSection(
    BuildContext context,
    AudioPlayerService playerService,
  ) {
    if (playerService.queue.isEmpty) {
      return const Center(child: Text('Queue is empty'));
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          alignment: Alignment.centerLeft,
          child: Row(
            children: [
              Text('Queue', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(width: 8),
              Text(
                '(${playerService.queue.length} tracks)',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: playerService.queue.length,
            itemBuilder: (context, index) {
              final item = playerService.queue[index];
              final isCurrent = index == playerService.queueIndex;

              return ListTile(
                leading: isCurrent
                    ? const Icon(Icons.play_arrow)
                    : Text('${index + 1}'),
                title: Text(
                  item.track.name,
                  style: isCurrent
                      ? TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        )
                      : null,
                ),
                subtitle: Text(item.album.artist ?? 'Unknown Artist'),
                trailing: Text(item.track.durationString),
                selected: isCurrent,
                enabled: !isCurrent,
                onTap: isCurrent
                    ? null
                    : () {
                        playerService.skipToQueueIndex(index);
                      },
              );
            },
          ),
        ),
      ],
    );
  }
}

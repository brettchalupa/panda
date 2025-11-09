import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'audio_player_service.dart';
import 'now_playing_screen.dart';

class NowPlayingBar extends StatelessWidget {
  const NowPlayingBar({super.key});

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
      return const SizedBox.shrink();
    }

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const NowPlayingScreen()),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          border: Border(
            top: BorderSide(color: Theme.of(context).dividerColor),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Progress bar
            LinearProgressIndicator(
              value: playerService.progress,
              minHeight: 2,
              backgroundColor: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest,
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  // Album art
                  if (playerService.albumArtUrl != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.network(
                        playerService.albumArtUrl!,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.album, size: 48),
                      ),
                    )
                  else
                    const Icon(Icons.album, size: 48),
                  const SizedBox(width: 12),
                  // Track info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          playerService.currentTrack!.name,
                          style: Theme.of(context).textTheme.titleSmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          playerService.currentAlbum?.artist ?? '',
                          style: Theme.of(context).textTheme.bodySmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${_formatDuration(playerService.position)} / ${_formatDuration(playerService.duration)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  // Previous button
                  IconButton(
                    icon: const Icon(Icons.skip_previous),
                    onPressed: playerService.hasPrevious
                        ? playerService.playPrevious
                        : null,
                  ),
                  // Play/pause button
                  IconButton(
                    icon: Icon(
                      playerService.isPlaying ? Icons.pause : Icons.play_arrow,
                    ),
                    onPressed: playerService.togglePlayPause,
                  ),
                  // Next button
                  IconButton(
                    icon: const Icon(Icons.skip_next),
                    onPressed: playerService.hasNext
                        ? playerService.playNext
                        : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

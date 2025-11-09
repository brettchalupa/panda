import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'jellyfin_api.dart';
import 'audio_player_service.dart';

class AlbumDetailScreen extends StatefulWidget {
  final JellyfinApi api;
  final Album album;

  const AlbumDetailScreen({super.key, required this.api, required this.album});

  @override
  State<AlbumDetailScreen> createState() => _AlbumDetailScreenState();
}

class _AlbumDetailScreenState extends State<AlbumDetailScreen> {
  List<Track>? _tracks;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadTracks();
  }

  Future<void> _loadTracks() async {
    try {
      final tracks = await widget.api.getTracks(widget.album.id);
      setState(() {
        _tracks = tracks;
        _isLoading = false;
      });

      // Precache album art
      if (mounted) {
        final albumArtUrl = widget.api.getAlbumArtUrl(
          widget.album.id,
          maxWidth: 500,
          maxHeight: 500,
        );
        if (albumArtUrl != null) {
          precacheImage(CachedNetworkImageProvider(albumArtUrl), context);
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _playTrack(Track track, AudioPlayerService playerService) {
    if (_tracks == null) return;

    final albumArtUrl = widget.api.getAlbumArtUrl(
      widget.album.id,
      maxWidth: 500,
      maxHeight: 500,
    );
    final trackIndex = _tracks!.indexOf(track);

    // Build queue from all tracks
    final queue = _tracks!.map((t) {
      return QueueItem(
        track: t,
        album: widget.album,
        streamUrl: widget.api.getStreamUrl(t.id),
        albumArtUrl: albumArtUrl,
      );
    }).toList();

    // Play the selected track with the full album queue
    final url = widget.api.getStreamUrl(track.id);
    playerService.playTrack(
      track,
      widget.album,
      url,
      albumArtUrl,
      queue: queue,
      queueIndex: trackIndex,
    );
  }

  Future<void> _toggleFavorite(Track track) async {
    try {
      final newFavoriteStatus = !track.isFavorite;
      if (track.isFavorite) {
        await widget.api.unmarkFavorite(track.id);
      } else {
        await widget.api.markFavorite(track.id);
      }
      // Update the track's favorite status in the local list
      setState(() {
        final index = _tracks!.indexWhere((t) => t.id == track.id);
        if (index != -1) {
          _tracks![index] = _tracks![index].copyWith(
            isFavorite: newFavoriteStatus,
          );
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update favorite: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final playerService = Provider.of<AudioPlayerService>(context);
    final albumArtUrl = widget.api.getAlbumArtUrl(
      widget.album.id,
      maxWidth: 500,
      maxHeight: 500,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.album.name),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 600;

          if (isWide) {
            // Two-column layout for wider screens
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left column: Album art and details
                SizedBox(
                  width: 300,
                  child: _buildAlbumInfo(context, albumArtUrl),
                ),
                const VerticalDivider(width: 1),
                // Right column: Track list
                Expanded(child: _buildTrackList(context, playerService)),
              ],
            );
          } else {
            // Stacked layout for narrow screens
            return Column(
              children: [
                _buildAlbumInfo(context, albumArtUrl),
                const Divider(height: 1),
                Expanded(child: _buildTrackList(context, playerService)),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildAlbumInfo(BuildContext context, String? albumArtUrl) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (albumArtUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: albumArtUrl,
                  width: 250,
                  height: 250,
                  fit: BoxFit.cover,
                  placeholder: (context, url) =>
                      const Icon(Icons.album, size: 250),
                  errorWidget: (context, url, error) =>
                      const Icon(Icons.album, size: 250),
                ),
              )
            else
              const Icon(Icons.album, size: 250),
            const SizedBox(height: 16),
            Text(
              widget.album.name,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            if (widget.album.artist != null) ...[
              const SizedBox(height: 8),
              Text(
                widget.album.artist!,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
            ],
            if (widget.album.year != null) ...[
              const SizedBox(height: 4),
              Text(
                widget.album.year.toString(),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTrackList(
    BuildContext context,
    AudioPlayerService playerService,
  ) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _errorMessage != null
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Error loading tracks',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(_errorMessage!),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isLoading = true;
                      _errorMessage = null;
                    });
                    _loadTracks();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          )
        : _tracks!.isEmpty
        ? const Center(child: Text('No tracks found'))
        : ListView.builder(
            itemCount: _tracks!.length,
            itemBuilder: (context, index) {
              final track = _tracks![index];
              final isCurrentTrack = playerService.currentTrack?.id == track.id;
              return ListTile(
                leading: Text(
                  track.trackNumber?.toString() ?? '',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                title: Text(track.name),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (track.durationString.isNotEmpty)
                      Text(
                        track.durationString,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    const SizedBox(width: 8),
                    if (isCurrentTrack && playerService.isPlaying)
                      const Icon(Icons.volume_up, size: 20),
                    IconButton(
                      icon: Icon(
                        track.isFavorite
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: track.isFavorite ? Colors.red : null,
                      ),
                      iconSize: 20,
                      onPressed: () => _toggleFavorite(track),
                    ),
                  ],
                ),
                selected: isCurrentTrack,
                onTap: () => _playTrack(track, playerService),
              );
            },
          );
  }
}

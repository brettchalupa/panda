import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'jellyfin_api.dart';
import 'audio_player_service.dart';

class FavoritesScreen extends StatefulWidget {
  final JellyfinApi api;

  const FavoritesScreen({super.key, required this.api});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<Track>? _favoriteTracks;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    try {
      final tracks = await widget.api.getFavoriteTracks();
      setState(() {
        _favoriteTracks = tracks;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _playTrack(Track track, AudioPlayerService playerService) {
    if (_favoriteTracks == null) return;

    final trackIndex = _favoriteTracks!.indexOf(track);

    // Build queue from all favorite tracks
    final queue = _favoriteTracks!.map((t) {
      final albumArtUrl = t.albumId != null
          ? widget.api.getAlbumArtUrl(t.albumId!, maxWidth: 600, maxHeight: 600)
          : null;
      return QueueItem(
        track: t,
        album: Album(
          id: t.albumId ?? '',
          name: t.album ?? 'Unknown Album',
          artist: t.albumArtist,
        ),
        streamUrl: widget.api.getStreamUrl(t.id),
        albumArtUrl: albumArtUrl,
      );
    }).toList();

    // Play the selected track with favorites queue
    final url = widget.api.getStreamUrl(track.id);
    final albumArtUrl = track.albumId != null
        ? widget.api.getAlbumArtUrl(
            track.albumId!,
            maxWidth: 600,
            maxHeight: 600,
          )
        : null;
    playerService.playTrack(
      track,
      Album(
        id: track.albumId ?? '',
        name: track.album ?? 'Unknown Album',
        artist: track.albumArtist,
      ),
      url,
      albumArtUrl,
      queue: queue,
      queueIndex: trackIndex,
    );
  }

  Future<void> _toggleFavorite(Track track) async {
    try {
      await widget.api.unmarkFavorite(track.id);
      // Reload favorites list
      _loadFavorites();
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorites'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Error loading favorites',
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
                      _loadFavorites();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : _favoriteTracks!.isEmpty
          ? const Center(child: Text('No favorite tracks'))
          : ListView.builder(
              itemCount: _favoriteTracks!.length,
              itemBuilder: (context, index) {
                final track = _favoriteTracks![index];
                final isCurrentTrack =
                    playerService.currentTrack?.id == track.id;
                final albumArtUrl = track.albumId != null
                    ? widget.api.getAlbumArtUrl(
                        track.albumId!,
                        maxWidth: 100,
                        maxHeight: 100,
                      )
                    : null;

                return ListTile(
                  leading: albumArtUrl != null
                      ? SizedBox(
                          width: 56,
                          height: 56,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              CachedNetworkImage(
                                imageUrl: albumArtUrl,
                                fit: BoxFit.cover,
                                fadeInDuration: Duration.zero,
                                fadeOutDuration: Duration.zero,
                                placeholder: (context, url) =>
                                    const Icon(Icons.album, size: 56),
                                errorWidget: (context, url, error) =>
                                    const Icon(Icons.album, size: 56),
                              ),
                              if (isCurrentTrack && playerService.isPlaying)
                                Container(
                                  color: Colors.black54,
                                  child: const Icon(
                                    Icons.volume_up,
                                    color: Colors.white,
                                  ),
                                ),
                            ],
                          ),
                        )
                      : SizedBox(
                          width: 56,
                          height: 56,
                          child: isCurrentTrack && playerService.isPlaying
                              ? const Icon(Icons.volume_up)
                              : const Icon(Icons.music_note),
                        ),
                  title: Text(track.name),
                  subtitle: Text(
                    '${track.albumArtist ?? 'Unknown Artist'} • ${track.album ?? 'Unknown Album'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (track.durationString.isNotEmpty)
                        Text(
                          track.durationString,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.favorite, color: Colors.red),
                        iconSize: 20,
                        onPressed: () => _toggleFavorite(track),
                      ),
                    ],
                  ),
                  selected: isCurrentTrack,
                  onTap: () => _playTrack(track, playerService),
                );
              },
            ),
    );
  }
}

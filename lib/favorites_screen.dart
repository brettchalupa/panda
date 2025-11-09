import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
      return QueueItem(
        track: t,
        album: Album(id: '', name: 'Favorites', artist: null),
        streamUrl: widget.api.getStreamUrl(t.id),
        albumArtUrl: null,
      );
    }).toList();

    // Play the selected track with favorites queue
    final url = widget.api.getStreamUrl(track.id);
    playerService.playTrack(
      track,
      Album(id: '', name: 'Favorites', artist: null),
      url,
      null,
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
                return ListTile(
                  leading: isCurrentTrack && playerService.isPlaying
                      ? const Icon(Icons.volume_up)
                      : const Icon(Icons.music_note),
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

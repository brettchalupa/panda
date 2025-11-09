import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'jellyfin_api.dart';
import 'session_manager.dart';
import 'album_detail_screen.dart';
import 'audio_player_service.dart';

class AlbumsScreen extends StatefulWidget {
  final JellyfinApi api;
  final String libraryId;
  final String libraryName;

  const AlbumsScreen({
    super.key,
    required this.api,
    required this.libraryId,
    required this.libraryName,
  });

  @override
  State<AlbumsScreen> createState() => _AlbumsScreenState();
}

class _AlbumsScreenState extends State<AlbumsScreen> {
  List<Album>? _albums;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAlbums();
  }

  Future<void> _loadAlbums() async {
    try {
      final albums = await widget.api.getAlbums(widget.libraryId);
      setState(() {
        _albums = albums;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await SessionManager.clearSession();
      // Pop back to main screen
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.libraryName),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Error loading albums',
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
                            _loadAlbums();
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : _albums!.isEmpty
                ? const Center(child: Text('No albums found'))
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 200,
                          childAspectRatio: 0.75,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                    itemCount: _albums!.length,
                    itemBuilder: (context, index) {
                      final album = _albums![index];
                      return _AlbumCard(api: widget.api, album: album);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _AlbumCard extends StatelessWidget {
  final JellyfinApi api;
  final Album album;

  const _AlbumCard({required this.api, required this.album});

  Future<void> _playAlbum(BuildContext context) async {
    final playerService = Provider.of<AudioPlayerService>(
      context,
      listen: false,
    );

    try {
      final tracks = await api.getTracks(album.id);
      if (tracks.isEmpty) return;

      final albumArtUrl = api.getAlbumArtUrl(album.id);
      final queue = tracks.map((t) {
        return QueueItem(
          track: t,
          album: album,
          streamUrl: api.getStreamUrl(t.id),
          albumArtUrl: albumArtUrl,
        );
      }).toList();

      final firstTrack = tracks.first;
      final streamUrl = api.getStreamUrl(firstTrack.id);

      await playerService.playTrack(
        firstTrack,
        album,
        streamUrl,
        albumArtUrl,
        queue: queue,
        queueIndex: 0,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error playing album: $e')));
      }
    }
  }

  void _viewAlbum(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AlbumDetailScreen(api: api, album: album),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final albumArtUrl = api.getAlbumArtUrl(album.id);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _viewAlbum(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (albumArtUrl != null)
                    Image.network(
                      albumArtUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.album, size: 64),
                    )
                  else
                    const Icon(Icons.album, size: 64),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: IconButton(
                      icon: const Icon(Icons.play_circle_filled),
                      iconSize: 32,
                      color: Colors.white,
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black54,
                      ),
                      onPressed: () => _playAlbum(context),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    album.name,
                    style: Theme.of(context).textTheme.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (album.artist != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      album.artist!,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (album.year != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      album.year.toString(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

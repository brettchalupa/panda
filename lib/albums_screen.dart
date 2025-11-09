import 'package:flutter/material.dart';
import 'jellyfin_api.dart';
import 'session_manager.dart';
import 'album_detail_screen.dart';

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
      body: _isLoading
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
          : ListView.builder(
              itemCount: _albums!.length,
              itemBuilder: (context, index) {
                final album = _albums![index];
                return ListTile(
                  leading: const Icon(Icons.album),
                  title: Text(album.name),
                  subtitle: Text(
                    [
                      if (album.artist != null) album.artist,
                      if (album.year != null) album.year.toString(),
                    ].join(' • '),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            AlbumDetailScreen(api: widget.api, album: album),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'jellyfin_api.dart';

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
  final AudioPlayer _audioPlayer = AudioPlayer();
  Track? _currentTrack;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _loadTracks();
    _setupAudioPlayer();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _setupAudioPlayer() {
    _audioPlayer.onPlayerStateChanged.listen((state) {
      setState(() {
        _isPlaying = state == PlayerState.playing;
      });
    });
  }

  Future<void> _loadTracks() async {
    try {
      final tracks = await widget.api.getTracks(widget.album.id);
      setState(() {
        _tracks = tracks;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _playTrack(Track track) async {
    final url = widget.api.getStreamUrl(track.id);
    await _audioPlayer.play(UrlSource(url));
    setState(() {
      _currentTrack = track;
    });
  }

  Future<void> _togglePlayPause() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.resume();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.album.name),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          // Album info header
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Icon(Icons.album, size: 100),
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
                  ),
                ],
                if (widget.album.year != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    widget.album.year.toString(),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ],
            ),
          ),
          const Divider(),
          // Track list
          Expanded(
            child: _isLoading
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
                      final isCurrentTrack = _currentTrack?.id == track.id;
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
                            if (isCurrentTrack && _isPlaying)
                              const Icon(Icons.volume_up, size: 20),
                          ],
                        ),
                        selected: isCurrentTrack,
                        onTap: () => _playTrack(track),
                      );
                    },
                  ),
          ),
          // Now playing bar
          if (_currentTrack != null)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                border: Border(
                  top: BorderSide(color: Theme.of(context).dividerColor),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _currentTrack!.name,
                          style: Theme.of(context).textTheme.titleSmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          widget.album.artist ?? '',
                          style: Theme.of(context).textTheme.bodySmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                    onPressed: _togglePlayPause,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

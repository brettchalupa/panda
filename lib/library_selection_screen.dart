import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'jellyfin_api.dart';
import 'albums_screen.dart';

class LibrarySelectionScreen extends StatefulWidget {
  final JellyfinApi api;

  const LibrarySelectionScreen({super.key, required this.api});

  @override
  State<LibrarySelectionScreen> createState() => _LibrarySelectionScreenState();
}

class _LibrarySelectionScreenState extends State<LibrarySelectionScreen> {
  List<MediaFolder>? _folders;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadFolders();
  }

  Future<void> _loadFolders() async {
    try {
      final folders = await widget.api.getMediaFolders();
      setState(() {
        _folders = folders.where((f) => f.isMusic).toList();
        _isLoading = false;
      });

      // Auto-navigate to last selected library
      final prefs = await SharedPreferences.getInstance();
      final lastLibraryId = prefs.getString('last_library_id');
      if (lastLibraryId != null && mounted) {
        final lastLibrary = _folders?.firstWhere(
          (f) => f.id == lastLibraryId,
          orElse: () => _folders!.first,
        );
        if (lastLibrary != null) {
          // Navigate after a short delay to let the UI settle
          Future.delayed(const Duration(milliseconds: 100), () {
            if (mounted) {
              _selectLibrary(lastLibrary);
            }
          });
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _selectLibrary(MediaFolder folder) async {
    // Save the selected library
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_library_id', folder.id);

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AlbumsScreen(
            api: widget.api,
            libraryId: folder.id,
            libraryName: folder.name,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Music Library'),
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
                    'Error loading libraries',
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
                      _loadFolders();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : _folders!.isEmpty
          ? const Center(child: Text('No music libraries found'))
          : ListView.builder(
              itemCount: _folders!.length,
              itemBuilder: (context, index) {
                final folder = _folders![index];
                return ListTile(
                  leading: const Icon(Icons.library_music),
                  title: Text(folder.name),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _selectLibrary(folder),
                );
              },
            ),
    );
  }
}

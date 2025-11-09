import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'jellyfin_api.dart';
import 'albums_screen.dart';
import 'now_playing_bar.dart';

/// A global app shell that provides persistent now playing bar across navigation
class AppShell extends StatefulWidget {
  final JellyfinApi api;

  const AppShell({super.key, required this.api});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  String? _libraryId;
  String? _libraryName;
  bool _isLoading = true;
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _loadLibrary();
  }

  Future<void> _loadLibrary() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final libraryId = prefs.getString('last_library_id');
      final libraryName = prefs.getString('last_library_name');

      if (libraryId != null && libraryName != null) {
        if (mounted) {
          setState(() {
            _libraryId = libraryId;
            _libraryName = libraryName;
            _isLoading = false;
          });
        }
      } else {
        // No library selected, need to select one from settings
        final folders = await widget.api.getMediaFolders();
        final musicFolders = folders.where((f) => f.isMusic).toList();

        if (musicFolders.isNotEmpty) {
          final firstLibrary = musicFolders.first;
          await prefs.setString('last_library_id', firstLibrary.id);
          await prefs.setString('last_library_name', firstLibrary.name);

          if (mounted) {
            setState(() {
              _libraryId = firstLibrary.id;
              _libraryName = firstLibrary.name;
              _isLoading = false;
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_libraryId == null || _libraryName == null) {
      return Scaffold(
        body: Center(
          child: Text('No music library found. Please check settings.'),
        ),
      );
    }

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () {
          // Use the GlobalKey to access the nested navigator directly
          if (_navigatorKey.currentState?.canPop() ?? false) {
            _navigatorKey.currentState!.pop();
          }
        },
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          body: Column(
            children: [
              Expanded(
                child: Navigator(
                  key: _navigatorKey,
                  onGenerateRoute: (settings) {
                    return MaterialPageRoute(
                      builder: (context) => AlbumsScreen(
                        api: widget.api,
                        libraryId: _libraryId!,
                        libraryName: _libraryName!,
                        onLibraryChanged: _loadLibrary,
                      ),
                      settings: settings,
                    );
                  },
                ),
              ),
              NowPlayingBar(api: widget.api),
            ],
          ),
        ),
      ),
    );
  }
}

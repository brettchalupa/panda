import 'package:flutter/material.dart';
import 'jellyfin_api.dart';
import 'library_selection_screen.dart';
import 'now_playing_bar.dart';

/// A global app shell that provides persistent now playing bar across navigation
class AppShell extends StatelessWidget {
  final JellyfinApi api;

  const AppShell({super.key, required this.api});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: Navigator(
              onGenerateRoute: (settings) {
                return MaterialPageRoute(
                  builder: (context) => LibrarySelectionScreen(api: api),
                  settings: settings,
                );
              },
            ),
          ),
          NowPlayingBar(api: api),
        ],
      ),
    );
  }
}

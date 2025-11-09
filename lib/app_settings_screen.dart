import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'jellyfin_api.dart';
import 'session_manager.dart';
import 'library_selection_screen.dart';

class AppSettingsScreen extends StatefulWidget {
  final JellyfinApi api;

  const AppSettingsScreen({super.key, required this.api});

  @override
  State<AppSettingsScreen> createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends State<AppSettingsScreen> {
  String? _libraryName;
  String? _userName;
  String? _serverUrl;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _libraryName = prefs.getString('last_library_name');
      _serverUrl = prefs.getString('server_url');
      _userName = widget.api.userName;
    });
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

  void _changeLibrary() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LibrarySelectionScreen(api: widget.api),
      ),
    );

    if (result == true && mounted) {
      // Library was changed, pop back to albums screen
      // which will trigger AppShell to reload
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView(
        children: [
          // Library Section
          ListTile(
            title: Text(
              'Library',
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.library_music),
            title: Text(_libraryName ?? 'Not selected'),
            subtitle: const Text('Music library'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _changeLibrary,
          ),
          const Divider(),

          // Server Info Section
          ListTile(
            title: Text(
              'Server',
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dns),
            title: const Text('Server URL'),
            subtitle: Text(_serverUrl ?? 'Unknown'),
          ),
          const Divider(),

          // User Info Section
          ListTile(
            title: Text('User', style: Theme.of(context).textTheme.titleSmall),
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Username'),
            subtitle: Text(_userName ?? 'Unknown'),
          ),
          const Divider(),

          // Actions
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Sign Out', style: TextStyle(color: Colors.red)),
            onTap: _signOut,
          ),
        ],
      ),
    );
  }
}

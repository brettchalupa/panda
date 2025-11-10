import 'custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'jellyfin_api.dart';
import 'session_manager.dart';
import 'library_selection_screen.dart';
import 'theme_manager.dart';

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
  String? _version;
  String? _buildNumber;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final packageInfo = await PackageInfo.fromPlatform();

    setState(() {
      _libraryName = prefs.getString('last_library_name');
      _serverUrl = prefs.getString('server_url');
      _userName = widget.api.userName;
      _version = packageInfo.version;
      _buildNumber = packageInfo.buildNumber;
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

  String _getThemeModeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'Auto';
    }
  }

  Future<void> _showThemeDialog(
    BuildContext context,
    ThemeManager themeManager,
  ) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Light'),
              trailing: themeManager.themeMode == ThemeMode.light
                  ? const Icon(Icons.check)
                  : null,
              onTap: () {
                themeManager.setThemeMode(ThemeMode.light);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Dark'),
              trailing: themeManager.themeMode == ThemeMode.dark
                  ? const Icon(Icons.check)
                  : null,
              onTap: () {
                themeManager.setThemeMode(ThemeMode.dark);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Auto'),
              subtitle: const Text('Follow system setting'),
              trailing: themeManager.themeMode == ThemeMode.system
                  ? const Icon(Icons.check)
                  : null,
              onTap: () {
                themeManager.setThemeMode(ThemeMode.system);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context);

    return Scaffold(
      appBar: CustomAppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          // Appearance Section
          ListTile(
            title: Text(
              'Appearance',
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.palette),
            title: const Text('Theme'),
            subtitle: Text(_getThemeModeLabel(themeManager.themeMode)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showThemeDialog(context, themeManager),
          ),
          const Divider(),

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

          // App Info Section
          ListTile(
            title: Text('App', style: Theme.of(context).textTheme.titleSmall),
          ),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('Version'),
            subtitle: Text(
              _version != null && _buildNumber != null
                  ? '$_version+$_buildNumber'
                  : 'Loading...',
            ),
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

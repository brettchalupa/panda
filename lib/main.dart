import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'settings_screen.dart';
import 'login_screen.dart';
import 'audio_player_service.dart';
import 'session_manager.dart';
import 'jellyfin_api.dart';
import 'app_shell.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AudioPlayerService(),
      child: MaterialApp(
        title: 'Stingray',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        ),
        home: const MyHomePage(title: 'Stingray'),
        builder: (context, child) {
          return _EscapeHandler(child: child!);
        },
      ),
    );
  }
}

class _EscapeHandler extends StatelessWidget {
  final Widget child;

  const _EscapeHandler({required this.child});

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () {
          final navigator = Navigator.of(context, rootNavigator: false);
          if (navigator.canPop()) {
            navigator.pop();
          }
        },
      },
      child: Focus(autofocus: true, child: child),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String _status = 'Not checked';
  String _serverUrl = '';
  bool _hasServer = false;

  @override
  void initState() {
    super.initState();
    _loadServerUrl();
  }

  Future<void> _loadServerUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final serverUrl = prefs.getString('server_url');

    setState(() {
      if (serverUrl != null && serverUrl.isNotEmpty) {
        _serverUrl = serverUrl;
        _hasServer = true;
      } else {
        _hasServer = false;
        _status = 'No server configured';
      }
    });

    // Check if already logged in
    if (_hasServer && mounted) {
      final hasSession = await SessionManager.hasSession();
      if (hasSession) {
        // Auto-login with existing session
        final accessToken = await SessionManager.getAccessToken();
        final userId = await SessionManager.getUserId();

        if (accessToken != null && userId != null && mounted) {
          final api = JellyfinApi(_serverUrl);
          api.accessToken = accessToken;
          api.userId = userId;

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => AppShell(api: api)),
          );
          return;
        }
      }
    }

    // If no server configured, show settings
    if (!_hasServer && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _openSettings();
      });
    }
  }

  Future<void> _openSettings() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    );

    if (result == true) {
      _loadServerUrl();
    }
  }

  void _login() {
    if (!_hasServer) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please configure server first')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LoginScreen(serverUrl: _serverUrl),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _openSettings,
            tooltip: 'Settings',
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Jellyfin Music Player',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (_hasServer)
              Text(_serverUrl, style: Theme.of(context).textTheme.bodySmall),
            if (!_hasServer)
              Text(_status, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: _hasServer ? _login : _openSettings,
              icon: Icon(_hasServer ? Icons.login : Icons.settings),
              label: Text(_hasServer ? 'Sign In' : 'Configure Server'),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'settings_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stingray',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Stingray'),
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
  bool _isLoading = false;
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
        _status = 'Ready to check';
      } else {
        _hasServer = false;
        _status = 'No server configured';
      }
    });

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

  Future<void> _checkHealth() async {
    if (!_hasServer) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please configure server first')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _status = 'Checking...';
    });

    try {
      final response = await http.get(Uri.parse('$_serverUrl/health'));
      setState(() {
        _isLoading = false;
        if (response.statusCode == 200) {
          _status = 'Server is healthy! (${response.statusCode})';
        } else {
          _status = 'Server returned: ${response.statusCode}';
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _status = 'Error: $e';
      });
    }
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
              'Jellyfin Server Status:',
              style: TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 8),
            if (_hasServer)
              Text(_serverUrl, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 20),
            Text(
              _status,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _isLoading ? null : _checkHealth,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Check Health'),
            ),
          ],
        ),
      ),
    );
  }
}

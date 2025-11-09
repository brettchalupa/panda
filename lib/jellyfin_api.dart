import 'dart:convert';
import 'package:http/http.dart' as http;

class JellyfinApi {
  final String serverUrl;
  String? accessToken;
  String? userId;

  JellyfinApi(this.serverUrl);

  Map<String, String> _getAuthHeaders() {
    // Jellyfin requires this header for API identification
    return {
      'X-Emby-Authorization':
          'MediaBrowser Client="Stingray", Device="Flutter", DeviceId="stingray-1", Version="1.0.0"',
    };
  }

  Future<AuthenticationResult> authenticateByName(
    String username,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse('$serverUrl/Users/AuthenticateByName'),
      headers: {'Content-Type': 'application/json', ..._getAuthHeaders()},
      body: jsonEncode({'Username': username, 'Pw': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final result = AuthenticationResult.fromJson(data);
      accessToken = result.accessToken;
      userId = result.userId;
      return result;
    } else {
      throw Exception(
        'Authentication failed: ${response.statusCode} - ${response.body}',
      );
    }
  }

  Future<List<MediaFolder>> getMediaFolders() async {
    if (accessToken == null || userId == null) {
      throw Exception('Not authenticated');
    }

    final response = await http.get(
      Uri.parse('$serverUrl/Library/MediaFolders?userId=$userId'),
      headers: {'X-Emby-Token': accessToken!, ..._getAuthHeaders()},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final items = data['Items'] as List;
      return items.map((item) => MediaFolder.fromJson(item)).toList();
    } else {
      throw Exception('Failed to get media folders: ${response.statusCode}');
    }
  }

  Future<List<Album>> getAlbums(String? parentId) async {
    if (accessToken == null || userId == null) {
      throw Exception('Not authenticated');
    }

    final uri = Uri.parse('$serverUrl/Items').replace(
      queryParameters: {
        'userId': userId,
        'includeItemTypes': 'MusicAlbum',
        'sortBy': 'SortName',
        'sortOrder': 'Ascending',
        'recursive': 'true',
        if (parentId != null) 'parentId': parentId,
      },
    );

    final response = await http.get(
      uri,
      headers: {'X-Emby-Token': accessToken!, ..._getAuthHeaders()},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final items = data['Items'] as List;
      return items.map((item) => Album.fromJson(item)).toList();
    } else {
      throw Exception('Failed to get albums: ${response.statusCode}');
    }
  }

  Future<List<Track>> getTracks(String albumId) async {
    if (accessToken == null || userId == null) {
      throw Exception('Not authenticated');
    }

    final uri = Uri.parse('$serverUrl/Items').replace(
      queryParameters: {
        'userId': userId,
        'parentId': albumId,
        'sortBy': 'SortName',
        'sortOrder': 'Ascending',
      },
    );

    final response = await http.get(
      uri,
      headers: {'X-Emby-Token': accessToken!, ..._getAuthHeaders()},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final items = data['Items'] as List;
      return items.map((item) => Track.fromJson(item)).toList();
    } else {
      throw Exception('Failed to get tracks: ${response.statusCode}');
    }
  }

  String getStreamUrl(String itemId) {
    return '$serverUrl/Audio/$itemId/stream?static=true&api_key=$accessToken';
  }
}

class AuthenticationResult {
  final String? accessToken;
  final String? userId;
  final String? userName;

  AuthenticationResult({
    required this.accessToken,
    required this.userId,
    required this.userName,
  });

  factory AuthenticationResult.fromJson(Map<String, dynamic> json) {
    return AuthenticationResult(
      accessToken: json['AccessToken'] as String?,
      userId: json['User']?['Id'] as String?,
      userName: json['User']?['Name'] as String?,
    );
  }
}

class MediaFolder {
  final String id;
  final String name;
  final String? collectionType;

  MediaFolder({required this.id, required this.name, this.collectionType});

  factory MediaFolder.fromJson(Map<String, dynamic> json) {
    return MediaFolder(
      id: json['Id'] as String,
      name: json['Name'] as String,
      collectionType: json['CollectionType'] as String?,
    );
  }

  bool get isMusic => collectionType == 'music';
}

class Album {
  final String id;
  final String name;
  final String? artist;
  final int? year;

  Album({required this.id, required this.name, this.artist, this.year});

  factory Album.fromJson(Map<String, dynamic> json) {
    return Album(
      id: json['Id'] as String,
      name: json['Name'] as String,
      artist: json['AlbumArtist'] as String?,
      year: json['ProductionYear'] as int?,
    );
  }
}

class Track {
  final String id;
  final String name;
  final int? trackNumber;
  final int? runtime; // in ticks (10000 ticks = 1ms)

  Track({required this.id, required this.name, this.trackNumber, this.runtime});

  factory Track.fromJson(Map<String, dynamic> json) {
    return Track(
      id: json['Id'] as String,
      name: json['Name'] as String,
      trackNumber: json['IndexNumber'] as int?,
      runtime: json['RunTimeTicks'] as int?,
    );
  }

  String get durationString {
    if (runtime == null) return '';
    final totalSeconds = runtime! ~/ 10000000; // Convert ticks to seconds
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}

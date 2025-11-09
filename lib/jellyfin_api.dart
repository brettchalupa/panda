import 'dart:convert';
import 'package:http/http.dart' as http;

class JellyfinApi {
  final String serverUrl;
  String? accessToken;
  String? userId;
  String? userName;

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
      userName = result.userName;
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

  String? getAlbumArtUrl(String itemId, {int? maxWidth, int? maxHeight}) {
    if (accessToken == null) return null;
    final params = <String, String>{
      'api_key': accessToken!,
      if (maxWidth != null) 'maxWidth': maxWidth.toString(),
      if (maxHeight != null) 'maxHeight': maxHeight.toString(),
      'quality': '90',
    };
    final query = params.entries.map((e) => '${e.key}=${e.value}').join('&');
    return '$serverUrl/Items/$itemId/Images/Primary?$query';
  }

  Future<void> markFavorite(String itemId) async {
    if (accessToken == null || userId == null) {
      throw Exception('Not authenticated');
    }

    final response = await http.post(
      Uri.parse('$serverUrl/UserFavoriteItems/$itemId'),
      headers: {'X-Emby-Token': accessToken!, ..._getAuthHeaders()},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to mark as favorite: ${response.statusCode}');
    }
  }

  Future<void> unmarkFavorite(String itemId) async {
    if (accessToken == null || userId == null) {
      throw Exception('Not authenticated');
    }

    final response = await http.delete(
      Uri.parse('$serverUrl/UserFavoriteItems/$itemId'),
      headers: {'X-Emby-Token': accessToken!, ..._getAuthHeaders()},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to unmark as favorite: ${response.statusCode}');
    }
  }

  Future<List<Track>> getFavoriteTracks() async {
    if (accessToken == null || userId == null) {
      throw Exception('Not authenticated');
    }

    final uri = Uri.parse('$serverUrl/Items').replace(
      queryParameters: {
        'userId': userId,
        'includeItemTypes': 'Audio',
        'filters': 'IsFavorite',
        'sortBy': 'SortName',
        'sortOrder': 'Ascending',
        'recursive': 'true',
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
      throw Exception('Failed to get favorite tracks: ${response.statusCode}');
    }
  }

  // Playback reporting
  Future<void> reportPlaybackStart(
    String itemId,
    int positionTicks,
  ) async {
    if (accessToken == null || userId == null) {
      throw Exception('Not authenticated');
    }

    final response = await http.post(
      Uri.parse('$serverUrl/Sessions/Playing'),
      headers: {
        'Content-Type': 'application/json',
        'X-Emby-Token': accessToken!,
        ..._getAuthHeaders(),
      },
      body: jsonEncode({
        'ItemId': itemId,
        'PositionTicks': positionTicks,
        'IsPaused': false,
        'PlayMethod': 'DirectStream',
      }),
    );

    if (response.statusCode != 204 && response.statusCode != 200) {
      throw Exception('Failed to report playback start: ${response.statusCode}');
    }
  }

  Future<void> reportPlaybackProgress(
    String itemId,
    int positionTicks,
    bool isPaused,
  ) async {
    if (accessToken == null || userId == null) {
      throw Exception('Not authenticated');
    }

    final response = await http.post(
      Uri.parse('$serverUrl/Sessions/Playing/Progress'),
      headers: {
        'Content-Type': 'application/json',
        'X-Emby-Token': accessToken!,
        ..._getAuthHeaders(),
      },
      body: jsonEncode({
        'ItemId': itemId,
        'PositionTicks': positionTicks,
        'IsPaused': isPaused,
        'PlayMethod': 'DirectStream',
      }),
    );

    if (response.statusCode != 204 && response.statusCode != 200) {
      throw Exception(
        'Failed to report playback progress: ${response.statusCode}',
      );
    }
  }

  Future<void> reportPlaybackStopped(
    String itemId,
    int positionTicks,
  ) async {
    if (accessToken == null || userId == null) {
      throw Exception('Not authenticated');
    }

    final response = await http.post(
      Uri.parse('$serverUrl/Sessions/Playing/Stopped'),
      headers: {
        'Content-Type': 'application/json',
        'X-Emby-Token': accessToken!,
        ..._getAuthHeaders(),
      },
      body: jsonEncode({
        'ItemId': itemId,
        'PositionTicks': positionTicks,
        'PlayMethod': 'DirectStream',
      }),
    );

    if (response.statusCode != 204 && response.statusCode != 200) {
      throw Exception(
        'Failed to report playback stopped: ${response.statusCode}',
      );
    }
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
  final bool isFavorite;
  final String? album;
  final String? albumId;
  final String? albumArtist;
  final List<String>? artists;
  final int playCount;

  Track({
    required this.id,
    required this.name,
    this.trackNumber,
    this.runtime,
    this.isFavorite = false,
    this.album,
    this.albumId,
    this.albumArtist,
    this.artists,
    this.playCount = 0,
  });

  factory Track.fromJson(Map<String, dynamic> json) {
    return Track(
      id: json['Id'] as String,
      name: json['Name'] as String,
      trackNumber: json['IndexNumber'] as int?,
      runtime: json['RunTimeTicks'] as int?,
      isFavorite: json['UserData']?['IsFavorite'] as bool? ?? false,
      album: json['Album'] as String?,
      albumId: json['AlbumId'] as String?,
      albumArtist: json['AlbumArtist'] as String?,
      artists: (json['Artists'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      playCount: json['UserData']?['PlayCount'] as int? ?? 0,
    );
  }

  Track copyWith({
    String? id,
    String? name,
    int? trackNumber,
    int? runtime,
    bool? isFavorite,
    String? album,
    String? albumId,
    String? albumArtist,
    List<String>? artists,
    int? playCount,
  }) {
    return Track(
      id: id ?? this.id,
      name: name ?? this.name,
      trackNumber: trackNumber ?? this.trackNumber,
      runtime: runtime ?? this.runtime,
      isFavorite: isFavorite ?? this.isFavorite,
      album: album ?? this.album,
      albumId: albumId ?? this.albumId,
      albumArtist: albumArtist ?? this.albumArtist,
      artists: artists ?? this.artists,
      playCount: playCount ?? this.playCount,
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

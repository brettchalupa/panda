import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SessionManager {
  static const _storage = FlutterSecureStorage();

  static const _keyAccessToken = 'access_token';
  static const _keyUserId = 'user_id';
  static const _keyUserName = 'user_name';

  static Future<void> saveSession({
    required String accessToken,
    required String userId,
    required String userName,
  }) async {
    await Future.wait([
      _storage.write(key: _keyAccessToken, value: accessToken),
      _storage.write(key: _keyUserId, value: userId),
      _storage.write(key: _keyUserName, value: userName),
    ]);
  }

  static Future<String?> getAccessToken() async {
    return await _storage.read(key: _keyAccessToken);
  }

  static Future<String?> getUserId() async {
    return await _storage.read(key: _keyUserId);
  }

  static Future<String?> getUserName() async {
    return await _storage.read(key: _keyUserName);
  }

  static Future<bool> hasSession() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  static Future<void> clearSession() async {
    await Future.wait([
      _storage.delete(key: _keyAccessToken),
      _storage.delete(key: _keyUserId),
      _storage.delete(key: _keyUserName),
    ]);
  }
}

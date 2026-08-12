import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Session tokens are secrets, so they live in the platform keystore/keychain
/// via flutter_secure_storage instead of Hive (which is unencrypted disk storage).
class TokenStorage {
  static const _accessTokenKey = 'visorroute_access_token';
  static const _refreshTokenKey = 'visorroute_refresh_token';

  final FlutterSecureStorage _storage;

  TokenStorage({FlutterSecureStorage? storage}) : _storage = storage ?? const FlutterSecureStorage();

  Future<void> saveTokens({required String accessToken, required String refreshToken}) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
  }

  Future<String?> readAccessToken() => _storage.read(key: _accessTokenKey);

  Future<String?> readRefreshToken() => _storage.read(key: _refreshTokenKey);

  Future<void> clear() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }
}

import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../features/playlist/models/playlist_data.dart';

import '../constants/key_constants.dart';

class AuthStorageService {
  final FlutterSecureStorage _secureStorage;

  AuthStorageService({FlutterSecureStorage? storage})
    : _secureStorage = storage ?? const FlutterSecureStorage();

  // In-memory cache for playlist data
  PlaylistData? _cachedPlaylistData;

  // Store all auth data (tokens + user ID)
  Future<void> storeAuthData({
    String? accessToken,
    String? refreshToken,
    String? userId,
    String? role,
  }) async {
    if (accessToken == null ||
        refreshToken == null ||
        userId == null ||
        role == null) {
      // Handle missing data: throw, log, or use defaults
      throw Exception('Missing required auth data');
    }

    // Store tokens and user ID in parallel for better performance
    await Future.wait([
      _secureStorage.write(key: KeyConstants.accessToken, value: accessToken),
      _secureStorage.write(key: KeyConstants.refreshToken, value: refreshToken),
      _secureStorage.write(key: KeyConstants.userId, value: userId),
      _secureStorage.write(key: KeyConstants.role, value: role),
    ]);
  }

  // Store just access token
  Future<void> storeAccessToken({required String accessToken}) async {
    await _secureStorage.write(
      key: KeyConstants.accessToken,
      value: accessToken,
    );
  }

  // Store just refresh token
  Future<void> storeRefreshToken({required String refreshToken}) async {
    await _secureStorage.write(
      key: KeyConstants.refreshToken,
      value: refreshToken,
    );
  }

  // Store just user ID
  Future<void> storeUserId(String userId) async {
    await _secureStorage.write(key: KeyConstants.userId, value: userId);
  }

  // Store playlist data
  Future<void> savePlaylistData(PlaylistData data) async {
    _cachedPlaylistData = data;
    await _secureStorage.write(
      key: KeyConstants.playlistData,
      value: jsonEncode(data.toJson()),
    );
  }

  // Get playlist data
  Future<PlaylistData> getPlaylistData() async {
    if (_cachedPlaylistData != null) {
      return _cachedPlaylistData!;
    }

    final String? data = await _secureStorage.read(
      key: KeyConstants.playlistData,
    );
    if (data == null || data.isEmpty) {
      _cachedPlaylistData = PlaylistData.empty();
      return _cachedPlaylistData!;
    }

    try {
      final Map<String, dynamic> decoded = jsonDecode(data);
      _cachedPlaylistData = PlaylistData.fromJson(decoded);
      return _cachedPlaylistData!;
    } catch (e) {
      _cachedPlaylistData = PlaylistData.empty();
      return _cachedPlaylistData!;
    }
  }

  // Store playlist data (LEGACY - for individual fields if still needed)
  Future<void> storePlaylistData({
    required String url,
    required String username,
    required String password,
  }) async {
    final data = PlaylistData(url: url, username: username, password: password);
    await savePlaylistData(data);

    // Also store individually for backward compatibility if necessary
    await Future.wait([
      _secureStorage.write(key: KeyConstants.playlistUrl, value: url),
      _secureStorage.write(key: KeyConstants.playlistUsername, value: username),
      _secureStorage.write(key: KeyConstants.playlistPassword, value: password),
    ]);
  }

  // Store multiple playlists
  Future<void> storePlaylists(List<Map<String, dynamic>> playlists) async {
    final String encodedData = jsonEncode(playlists);
    await _secureStorage.write(
      key: KeyConstants.playlistsList,
      value: encodedData,
    );
  }

  // Check user authenticater or not
  Future<bool> isAuthenticated() async {
    final accessToken = await getAccessToken();
    final roleString = await _secureStorage.read(key: KeyConstants.role);
    return accessToken != null &&
        accessToken.isNotEmpty &&
        roleString != null &&
        roleString.isNotEmpty;
  }

  // Get access token
  Future<String?> getAccessToken() async {
    final accessToken = await _secureStorage.read(
      key: KeyConstants.accessToken,
    );
    return accessToken;
  }

  // Get refresh token
  Future<String?> getRefreshToken() async {
    return await _secureStorage.read(key: KeyConstants.refreshToken);
  }

  // Get user ID
  Future<String?> getUserId() async {
    return await _secureStorage.read(key: KeyConstants.userId);
  }

  // Get playlist data (LEGACY)
  Future<String?> getPlaylistUrl() async {
    final data = await getPlaylistData();
    return data.url.isNotEmpty
        ? data.url
        : await _secureStorage.read(key: KeyConstants.playlistUrl);
  }

  Future<String?> getPlaylistUsername() async {
    final data = await getPlaylistData();
    return data.username.isNotEmpty
        ? data.username
        : await _secureStorage.read(key: KeyConstants.playlistUsername);
  }

  Future<String?> getPlaylistPassword() async {
    final data = await getPlaylistData();
    return data.password.isNotEmpty
        ? data.password
        : await _secureStorage.read(key: KeyConstants.playlistPassword);
  }

  // Get multiple playlists
  Future<List<Map<String, dynamic>>> getPlaylists() async {
    final String? data = await _secureStorage.read(
      key: KeyConstants.playlistsList,
    );
    if (data == null || data.isEmpty) return [];
    try {
      final List<dynamic> decoded = jsonDecode(data);
      return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      return [];
    }
  }

  // Get all auth data at once
  Future<Map<String, String?>> getAllAuthData() async {
    return {
      'accessToken': await getAccessToken(),
      'refreshToken': await getRefreshToken(),
      'userId': await getUserId(),
    };
  }

  // Clear all auth data (logout)
  Future<void> clearAuthData() async {
    _cachedPlaylistData = null;
    await Future.wait([
      _secureStorage.delete(key: KeyConstants.accessToken),
      _secureStorage.delete(key: KeyConstants.refreshToken),
      _secureStorage.delete(key: KeyConstants.userId),
      _secureStorage.delete(key: KeyConstants.playlistUrl),
      _secureStorage.delete(key: KeyConstants.playlistUsername),
      _secureStorage.delete(key: KeyConstants.playlistPassword),
      _secureStorage.delete(key: KeyConstants.playlistsList),
      _secureStorage.delete(key: KeyConstants.playlistData),
    ]);
  }

  // Check if user ID exists
  Future<bool> hasUserId() async {
    final userId = await getUserId();
    return userId != null && userId.isNotEmpty;
  }
}

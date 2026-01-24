import '../../../core/services/auth_storage_service.dart';
import 'playlist_data.dart';

enum ServerType { movies, movie, series, channels, live }

class ServerRequestModel {
  final String serverUrl;
  final String username;
  final String password;
  final String type;
  final int limit;
  final int page;

  ServerRequestModel({
    required this.serverUrl,
    required this.username,
    required this.password,
    required this.type,
    this.limit = 50,
    this.page = 1,
  });

  /// Creates a request model using the centralized playlist data from storage.
  static Future<ServerRequestModel> fromStorage({
    required ServerType type,
    int limit = 50,
    int page = 1,
    required AuthStorageService storage,
  }) async {
    final PlaylistData playlistData = await storage.getPlaylistData();
    return ServerRequestModel(
      serverUrl: playlistData.url,
      username: playlistData.username,
      password: playlistData.password,
      type: type.name,
      limit: limit,
      page: page,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'serverUrl': serverUrl,
      'username': username,
      'password': password,
      'type': type,
      'limit': limit,
      'page': page,
    };
  }

  ServerRequestModel copyWith({
    String? serverUrl,
    String? username,
    String? password,
    String? type,
    int? limit,
    int? page,
  }) {
    return ServerRequestModel(
      serverUrl: serverUrl ?? this.serverUrl,
      username: username ?? this.username,
      password: password ?? this.password,
      type: type ?? this.type,
      limit: limit ?? this.limit,
      page: page ?? this.page,
    );
  }

  factory ServerRequestModel.fromJson(Map<String, dynamic> json) {
    return ServerRequestModel(
      serverUrl: json['serverUrl'] ?? '',
      username: json['username'] ?? '',
      password: json['password'] ?? '',
      type: json['type'] ?? 'movies',
      limit: json['limit'] ?? 50,
      page: json['page'] ?? 1,
    );
  }
}

class SingleStreamRequestModel {
  final String serverUrl;
  final String username;
  final String password;
  final String streamType;
  final int streamId;

  SingleStreamRequestModel({
    required this.serverUrl,
    required this.username,
    required this.password,
    required this.streamType,
    required this.streamId,
  });

  /// Creates a request model using the centralized playlist data from storage.
  static Future<SingleStreamRequestModel> fromStorage({
    required ServerType streamType,
    required int streamId,
    required AuthStorageService storage,
  }) async {
    final PlaylistData playlistData = await storage.getPlaylistData();
    return SingleStreamRequestModel(
      serverUrl: playlistData.url,
      username: playlistData.username,
      password: playlistData.password,
      streamType: streamType.name,
      streamId: streamId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'serverUrl': serverUrl,
      'username': username,
      'password': password,
      'stream_type': streamType,
      'stream_id': streamId,
    };
  }
}

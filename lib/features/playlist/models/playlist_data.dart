import 'playlist_model.dart';

class PlaylistData {
  final String url;
  final String username;
  final String password;

  /// Backend id of the playlist these credentials belong to. Null for data
  /// saved before ids were stored, and right after adding a playlist (the
  /// add endpoint doesn't return one); [matchIdIn] recovers it.
  final String? id;

  PlaylistData({
    required this.url,
    required this.username,
    required this.password,
    this.id,
  });

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'username': username,
      'password': password,
      'id': ?id,
    };
  }

  factory PlaylistData.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    return PlaylistData(
      url: json['url'] ?? '',
      username: json['username'] ?? '',
      password: json['password'] ?? '',
      id: id is String && id.isNotEmpty ? id : null,
    );
  }

  factory PlaylistData.empty() {
    return PlaylistData(url: '', username: '', password: '');
  }

  factory PlaylistData.fromPlaylist(PlaylistModel playlist) {
    return PlaylistData(
      url: playlist.url ?? '',
      username: playlist.userName ?? '',
      password: playlist.password ?? '',
      id: playlist.id,
    );
  }

  PlaylistData copyWith({String? id}) => PlaylistData(
    url: url,
    username: username,
    password: password,
    id: id ?? this.id,
  );

  bool get isEmpty => url.isEmpty && username.isEmpty && password.isEmpty;
  bool get isNotEmpty => !isEmpty;

  /// The id of the playlist in [playlists] these credentials belong to: the
  /// stored [id] if it's still in the list, otherwise the playlist with the
  /// same URL, username and password (the backend rejects duplicates, so
  /// that match is unique).
  String? matchIdIn(List<PlaylistModel> playlists) {
    if (isEmpty) return null;
    if (id != null && playlists.any((p) => p.id == id)) return id;
    for (final p in playlists) {
      if (p.id != null &&
          p.url == url &&
          p.userName == username &&
          p.password == password) {
        return p.id;
      }
    }
    return null;
  }

  @override
  String toString() =>
      'PlaylistData(id: $id, url: $url, username: $username, password: ***)';
}

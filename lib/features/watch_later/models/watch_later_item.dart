import '../../playlist/models/server_request_model.dart';

/// A title saved for later on one playlist. Items are per playlist because
/// Xtream stream / series ids only mean something on the provider they came
/// from.
class WatchLaterItem {
  final String id;
  final String videoType; // 'movie' | 'series'
  final String videoId;
  final String title;
  final String thumbnail;

  /// Null only if the playlist was deleted and the backend didn't clean up.
  final String? playlistId;
  final String? playlistName;
  final DateTime? createdAt;

  const WatchLaterItem({
    required this.id,
    required this.videoType,
    required this.videoId,
    required this.title,
    required this.thumbnail,
    this.playlistId,
    this.playlistName,
    this.createdAt,
  });

  factory WatchLaterItem.fromJson(Map<String, dynamic> json) {
    // `playlist` is populated to { _id, name } by the list and add endpoints,
    // but may be a bare id or null.
    final playlist = json['playlist'];
    String? playlistId;
    String? playlistName;
    if (playlist is Map) {
      playlistId = playlist['_id']?.toString();
      playlistName = playlist['name']?.toString();
    } else if (playlist is String && playlist.isNotEmpty) {
      playlistId = playlist;
    }

    return WatchLaterItem(
      id: json['_id']?.toString() ?? '',
      videoType: json['videoType']?.toString() ?? 'movie',
      videoId: json['videoId']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      thumbnail: json['thumbnail']?.toString() ?? '',
      playlistId: playlistId,
      playlistName: playlistName,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
    );
  }

  bool get isSeries => videoType == 'series';

  ServerType get serverType => isSeries ? ServerType.series : ServerType.movies;

  int? get streamId => int.tryParse(videoId);
}

/// Whether a title is saved on the active playlist, for the player's button.
class WatchLaterStatus {
  final bool isSaved;
  final String? id;

  const WatchLaterStatus({required this.isSaved, this.id});

  factory WatchLaterStatus.fromJson(Map<String, dynamic> json) {
    final id = json['id']?.toString();
    return WatchLaterStatus(
      isSaved: json['isSaved'] == true,
      id: id == null || id.isEmpty ? null : id,
    );
  }
}

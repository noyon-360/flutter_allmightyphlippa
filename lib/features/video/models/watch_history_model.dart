class WatchHistoryModel {
  final String id;
  final String userId;
  final String videoId;
  final String videoType;
  final int? seasonNumber;
  final int? episodeNumber;
  final String? name;
  final double currentTime;
  final String thumbnail;
  final double duration;
  final double progressPercentage;
  final bool isCompleted;
  final bool isLoved;
  final DateTime? lastWatchedAt;

  WatchHistoryModel({
    required this.id,
    required this.userId,
    required this.videoId,
    required this.videoType,
    this.seasonNumber,
    this.episodeNumber,
    this.name = '',
    this.currentTime = 0,
    this.thumbnail = '',
    this.duration = 0,
    this.progressPercentage = 0,
    this.isCompleted = false,
    this.isLoved = false,
    this.lastWatchedAt,
  });

  factory WatchHistoryModel.fromJson(Map<String, dynamic> json) {
    return WatchHistoryModel(
      id: json['_id'] ?? '',
      userId: json['userId'] ?? '',
      videoId: json['videoId'] ?? '',
      videoType: json['videoType'] ?? '',
      seasonNumber: json['seasonNumber'],
      episodeNumber: json['episodeNumber'],
      name:
          json['name'] ??
          json['title'] ??
          '', // Handle potential key variations
      thumbnail: json['thumbnail'] ?? '',
      currentTime: (json['currentTime'] as num?)?.toDouble() ?? 0,
      duration: (json['duration'] as num?)?.toDouble() ?? 0,
      progressPercentage: (json['progressPercentage'] as num?)?.toDouble() ?? 0,
      isCompleted: json['isCompleted'] ?? false,
      isLoved: json['isLoved'] ?? false,
      lastWatchedAt: json['lastWatchedAt'] != null
          ? DateTime.tryParse(json['lastWatchedAt'])
          : null,
    );
  }
}

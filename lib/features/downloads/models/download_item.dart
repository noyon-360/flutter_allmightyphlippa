enum DownloadStatus { queued, downloading, completed, failed }

class DownloadItem {
  final String id;         // e.g. "movie_1234" or "series_5678"
  final String videoId;
  final String videoType;  // 'movie' or 'series'
  final String title;
  final String? thumbnail;
  final String url;
  final String localPath;
  final String ext;
  DownloadStatus status;
  double progress;         // 0.0 – 1.0
  int fileSize;            // bytes; 0 until known
  final DateTime createdAt;

  DownloadItem({
    required this.id,
    required this.videoId,
    required this.videoType,
    required this.title,
    this.thumbnail,
    required this.url,
    required this.localPath,
    required this.ext,
    this.status = DownloadStatus.queued,
    this.progress = 0.0,
    this.fileSize = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isCompleted => status == DownloadStatus.completed;
  bool get isDownloading => status == DownloadStatus.downloading;

  Map<String, dynamic> toMap() => {
    'id': id,
    'videoId': videoId,
    'videoType': videoType,
    'title': title,
    'thumbnail': thumbnail,
    'url': url,
    'localPath': localPath,
    'ext': ext,
    'status': status.name,
    'progress': progress,
    'fileSize': fileSize,
    'createdAt': createdAt.toIso8601String(),
  };

  factory DownloadItem.fromMap(Map<dynamic, dynamic> m) => DownloadItem(
    id: m['id'] as String,
    videoId: m['videoId'] as String,
    videoType: m['videoType'] as String,
    title: m['title'] as String,
    thumbnail: m['thumbnail'] as String?,
    url: m['url'] as String,
    localPath: m['localPath'] as String,
    ext: m['ext'] as String,
    status: DownloadStatus.values.firstWhere(
      (s) => s.name == m['status'],
      orElse: () => DownloadStatus.failed,
    ),
    progress: (m['progress'] as num).toDouble(),
    fileSize: (m['fileSize'] as num).toInt(),
    createdAt: DateTime.parse(m['createdAt'] as String),
  );
}

class LiveTvModel {
  final int num;
  final String name;
  final String streamType;
  final int streamId;
  final String streamIcon;
  final String epgChannelId;
  final String added;
  final int isAdult;
  final String categoryId;
  final List<int> categoryIds;
  final dynamic customSid;
  final int tvArchive;
  final String directSource;
  final int tvArchiveDuration;

  LiveTvModel({
    required this.num,
    required this.name,
    required this.streamType,
    required this.streamId,
    required this.streamIcon,
    required this.epgChannelId,
    required this.added,
    required this.isAdult,
    required this.categoryId,
    required this.categoryIds,
    this.customSid,
    required this.tvArchive,
    required this.directSource,
    required this.tvArchiveDuration,
  });

  factory LiveTvModel.fromJson(Map<String, dynamic> json) {
    return LiveTvModel(
      num: json['num'] ?? 0,
      name: json['name'] ?? '',
      streamType: json['stream_type'] ?? '',
      streamId: json['stream_id'] ?? 0,
      streamIcon: json['stream_icon'] ?? '',
      epgChannelId: json['epg_channel_id'] ?? '',
      added: json['added'] ?? '',
      isAdult: json['is_adult'] ?? 0,
      categoryId: json['category_id'] ?? '',
      categoryIds: json['category_ids'] != null
          ? List<int>.from(json['category_ids'])
          : [],
      customSid: json['custom_sid'],
      tvArchive: json['tv_archive'] ?? 0,
      directSource: json['direct_source'] ?? '',
      tvArchiveDuration: json['tv_archive_duration'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'num': num,
      'name': name,
      'stream_type': streamType,
      'stream_id': streamId,
      'stream_icon': streamIcon,
      'epg_channel_id': epgChannelId,
      'added': added,
      'is_adult': isAdult,
      'category_id': categoryId,
      'category_ids': categoryIds,
      'custom_sid': customSid,
      'tv_archive': tvArchive,
      'direct_source': directSource,
      'tv_archive_duration': tvArchiveDuration,
    };
  }
}

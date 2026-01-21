class MoviesResponseModel {
  final int num;
  final String name;
  final String streamType;
  final int streamId;
  final String streamIcon;
  final String rating;
  final double rating5Based;
  final String tmdb;
  final String trailer;
  final String added;
  final int isAdult;
  final String categoryId;
  final List<int> categoryIds;
  final String containerExtension;
  final String? customSid;
  final String directSource;

  MoviesResponseModel({
    required this.num,
    required this.name,
    required this.streamType,
    required this.streamId,
    required this.streamIcon,
    required this.rating,
    required this.rating5Based,
    required this.tmdb,
    required this.trailer,
    required this.added,
    required this.isAdult,
    required this.categoryId,
    required this.categoryIds,
    required this.containerExtension,
    this.customSid,
    required this.directSource,
  });

  factory MoviesResponseModel.fromJson(Map<String, dynamic> json) {
    return MoviesResponseModel(
      num: json['num'] ?? 0,
      name: json['name'] ?? '',
      streamType: json['stream_type'] ?? '',
      streamId: json['stream_id'] ?? 0,
      streamIcon: json['stream_icon'] ?? '',
      rating: json['rating'].toString(),
      rating5Based: _parseDouble(json['rating_5based']),
      tmdb: json['tmdb'].toString(),
      trailer: json['trailer'] ?? '',
      added: json['added'] ?? '',
      isAdult: json['is_adult'] ?? 0,
      categoryId: json['category_id'] ?? '',
      categoryIds: json['category_ids'] != null
          ? List<int>.from(json['category_ids'])
          : [],
      containerExtension: json['container_extension'] ?? '',
      customSid: json['custom_sid'],
      directSource: json['direct_source'] ?? '',
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'num': num,
      'name': name,
      'stream_type': streamType,
      'stream_id': streamId,
      'stream_icon': streamIcon,
      'rating': rating,
      'rating_5based': rating5Based,
      'tmdb': tmdb,
      'trailer': trailer,
      'added': added,
      'is_adult': isAdult,
      'category_id': categoryId,
      'category_ids': categoryIds,
      'container_extension': containerExtension,
      'custom_sid': customSid,
      'direct_source': directSource,
    };
  }
}

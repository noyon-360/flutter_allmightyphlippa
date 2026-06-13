class SingleMovieResponseModel {
  final StreamData streamData;
  final String playUrl;

  SingleMovieResponseModel({required this.streamData, required this.playUrl});

  factory SingleMovieResponseModel.fromJson(Map<String, dynamic> json) {
    return SingleMovieResponseModel(
      streamData: StreamData.fromJson(json['data'] ?? {}),
      playUrl: json['playUrl'] ?? '',
    );
  }
}

class StreamData {
  final MovieInfo info;
  final MovieData movieData;

  StreamData({required this.info, required this.movieData});

  factory StreamData.fromJson(Map<String, dynamic> json) {
    return StreamData(
      info: MovieInfo.fromJson(
        json['info'] is Map<String, dynamic> ? json['info'] : {},
      ),
      movieData: MovieData.fromJson(
        json['movie_data'] is Map<String, dynamic> ? json['movie_data'] : {},
      ),
    );
  }
}

class MovieInfo {
  final String kinopoiskUrl;
  final int tmdbId;
  final String name;
  final String oName;
  final String coverBig;
  final String movieImage;
  final String releaseDate;
  final int episodeRunTime;
  final String? youtubeTrailer;
  final String director;
  final String actors;
  final String cast;
  final String description;
  final String plot;
  final String age;
  final String mpaaRating;
  final int ratingCountKinopoisk;
  final String country;
  final String genre;
  final List<String> backdropPath;
  final int durationSecs;
  final String duration;
  final VideoInfo video;
  final AudioInfo audio;
  final int bitrate;
  final double rating;

  MovieInfo({
    required this.kinopoiskUrl,
    required this.tmdbId,
    required this.name,
    required this.oName,
    required this.coverBig,
    required this.movieImage,
    required this.releaseDate,
    required this.episodeRunTime,
    this.youtubeTrailer,
    required this.director,
    required this.actors,
    required this.cast,
    required this.description,
    required this.plot,
    required this.age,
    required this.mpaaRating,
    required this.ratingCountKinopoisk,
    required this.country,
    required this.genre,
    required this.backdropPath,
    required this.durationSecs,
    required this.duration,
    required this.video,
    required this.audio,
    required this.bitrate,
    required this.rating,
  });

  factory MovieInfo.fromJson(Map<String, dynamic> json) {
    return MovieInfo(
      kinopoiskUrl: json['kinopoisk_url'] ?? '',
      tmdbId: _parseInt(json['tmdb_id']),
      name: json['name'] ?? '',
      oName: json['o_name'] ?? '',
      coverBig: json['cover_big'] ?? '',
      movieImage: json['movie_image'] ?? '',
      releaseDate: json['releasedate'] ?? '',
      episodeRunTime: _parseInt(json['episode_run_time']),
      youtubeTrailer: json['youtube_trailer'],
      director: json['director'] ?? '',
      actors: json['actors'] ?? '',
      cast: json['cast'] ?? '',
      description: json['description'] ?? '',
      plot: json['plot'] ?? '',
      age: json['age'] ?? '',
      mpaaRating: json['mpaa_rating'] ?? '',
      ratingCountKinopoisk: _parseInt(json['rating_count_kinopoisk']),
      country: json['country'] ?? '',
      genre: json['genre'] ?? '',
      backdropPath:
          (json['backdrop_path'] as List?)?.map((e) => e.toString()).toList() ??
          [],
      durationSecs: _parseInt(json['duration_secs']),
      duration: json['duration'] ?? '',
      video: VideoInfo.fromJson(json['video'] ?? {}),
      audio: AudioInfo.fromJson(json['audio'] ?? {}),
      bitrate: _parseInt(json['bitrate']),
      rating: _parseDouble(json['rating']),
    );
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}

class VideoInfo {
  final String codecName;
  final int width;
  final int height;

  VideoInfo({
    required this.codecName,
    required this.width,
    required this.height,
  });

  factory VideoInfo.fromJson(Map<String, dynamic> json) {
    return VideoInfo(
      codecName: json['codec_name'] ?? '',
      width: json['width'] ?? 0,
      height: json['height'] ?? 0,
    );
  }
}

class AudioInfo {
  final String codecName;
  final String language;

  AudioInfo({required this.codecName, required this.language});

  factory AudioInfo.fromJson(Map<String, dynamic> json) {
    return AudioInfo(
      codecName: json['codec_name'] ?? '',
      language: json['tags'] != null ? json['tags']['language'] ?? '' : '',
    );
  }
}

class MovieData {
  final int streamId;
  final String name;
  final String added;
  final String categoryId;
  final List<int> categoryIds;
  final String containerExtension;
  final String customSid;
  final String directSource;

  MovieData({
    required this.streamId,
    required this.name,
    required this.added,
    required this.categoryId,
    required this.categoryIds,
    required this.containerExtension,
    required this.customSid,
    required this.directSource,
  });

  factory MovieData.fromJson(Map<String, dynamic> json) {
    return MovieData(
      streamId: _parseInt(json['stream_id']),
      name: json['name'] ?? '',
      added: json['added']?.toString() ?? '',
      categoryId: json['category_id']?.toString() ?? '',
      categoryIds: (json['category_ids'] as List?)
              ?.map((e) => _parseInt(e))
              .toList() ??
          [],
      containerExtension: json['container_extension'] ?? '',
      customSid: json['custom_sid']?.toString() ?? '',
      directSource: json['direct_source'] ?? '',
    );
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}

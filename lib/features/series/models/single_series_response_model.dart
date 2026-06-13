class SingleSeriesResponseModel {
  SeriesDataContent? data;
  String? playUrl;

  SingleSeriesResponseModel({this.data, this.playUrl});

  SingleSeriesResponseModel.fromJson(Map<String, dynamic> json) {
    data = json['data'] != null
        ? SeriesDataContent.fromJson(json['data'])
        : null;
    playUrl = json['playUrl'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    data['playUrl'] = playUrl;
    return data;
  }
}

class SeriesDataContent {
  List<Season>? seasons;
  SeriesInfo? info;
  Map<String, List<Episode>>? episodes;

  SeriesDataContent({this.seasons, this.info, this.episodes});

  SeriesDataContent.fromJson(Map<String, dynamic> json) {
    if (json['seasons'] != null) {
      seasons = <Season>[];
      json['seasons'].forEach((v) {
        seasons!.add(Season.fromJson(v));
      });
    }
    info = json['info'] != null ? SeriesInfo.fromJson(json['info']) : null;
    if (json['episodes'] != null) {
      episodes = {};
      json['episodes'].forEach((key, value) {
        if (value != null) {
          episodes![key] = <Episode>[];
          value.forEach((v) {
            episodes![key]!.add(Episode.fromJson(v));
          });
        }
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (seasons != null) {
      data['seasons'] = seasons!.map((v) => v.toJson()).toList();
    }
    if (info != null) {
      data['info'] = info!.toJson();
    }
    if (episodes != null) {
      final Map<String, dynamic> episodesMap = {};
      episodes!.forEach((key, value) {
        episodesMap[key] = value.map((v) => v.toJson()).toList();
      });
      data['episodes'] = episodesMap;
    }
    return data;
  }
}

class Season {
  String? name;
  String? episodeCount;
  String? overview;
  String? airDate;
  String? cover;
  String? coverTmdb;
  int? seasonNumber;
  String? coverBig;
  String? releaseDate;
  String? duration;

  List<Episode>? episodeModels;

  Season({
    this.name,
    this.episodeCount,
    this.overview,
    this.airDate,
    this.cover,
    this.coverTmdb,
    this.seasonNumber,
    this.coverBig,
    this.releaseDate,
    this.duration,
    this.episodeModels,
  });

  Season.fromJson(Map<String, dynamic> json) {
    name = json['name']?.toString();
    episodeCount = json['episode_count']?.toString();
    overview = json['overview']?.toString();
    airDate = json['air_date']?.toString();
    cover = json['cover']?.toString();
    coverTmdb = json['cover_tmdb']?.toString();
    seasonNumber = json['season_number'] is String
        ? int.tryParse(json['season_number'])
        : json['season_number'];
    coverBig = json['cover_big']?.toString();
    releaseDate = json['releaseDate']?.toString();
    duration = json['duration']?.toString();
    if (json['episodeModels'] != null) {
      episodeModels = <Episode>[];
      json['episodeModels'].forEach((v) {
        episodeModels!.add(Episode.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name;
    data['episode_count'] = episodeCount;
    data['overview'] = overview;
    data['air_date'] = airDate;
    data['cover'] = cover;
    data['cover_tmdb'] = coverTmdb;
    data['season_number'] = seasonNumber;
    data['cover_big'] = coverBig;
    data['releaseDate'] = releaseDate;
    data['duration'] = duration;
    if (episodeModels != null) {
      data['episodeModels'] = episodeModels!
          .map((v) => v.toJson())
          .toList();
    }
    return data;
  }
}

class SeriesInfo {
  String? name;
  String? cover;
  String? plot;
  String? cast;
  String? director;
  String? genre;
  String? releaseDate;
  String? lastModified;
  String? rating;
  String? rating5based;
  List<String>? backdropPath;
  String? tmdb;
  String? youtubeTrailer;
  String? episodeRunTime;
  String? categoryId;
  List<int>? categoryIds;

  SeriesInfo({
    this.name,
    this.cover,
    this.plot,
    this.cast,
    this.director,
    this.genre,
    this.releaseDate,
    this.lastModified,
    this.rating,
    this.rating5based,
    this.backdropPath,
    this.tmdb,
    this.youtubeTrailer,
    this.episodeRunTime,
    this.categoryId,
    this.categoryIds,
  });

  SeriesInfo.fromJson(Map<String, dynamic> json) {
    name = json['name']?.toString();
    cover = json['cover']?.toString();
    plot = json['plot']?.toString();
    cast = json['cast']?.toString();
    director = json['director']?.toString();
    genre = json['genre']?.toString();
    releaseDate = (json['releaseDate'] ?? json['release_date'])?.toString();
    lastModified = json['last_modified']?.toString();
    rating = json['rating']?.toString();
    rating5based = json['rating_5based']?.toString();
    if (json['backdrop_path'] != null) {
      backdropPath = List<String>.from(json['backdrop_path']);
    }
    tmdb = json['tmdb']?.toString();
    youtubeTrailer = json['youtube_trailer']?.toString();
    episodeRunTime = json['episode_run_time']?.toString();
    categoryId = json['category_id']?.toString();
    if (json['category_ids'] != null) {
      categoryIds = List<int>.from(json['category_ids']);
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name;
    data['cover'] = cover;
    data['plot'] = plot;
    data['cast'] = cast;
    data['director'] = director;
    data['genre'] = genre;
    data['releaseDate'] = releaseDate;
    data['last_modified'] = lastModified;
    data['rating'] = rating;
    data['rating_5based'] = rating5based;
    data['backdrop_path'] = backdropPath;
    data['tmdb'] = tmdb;
    data['youtube_trailer'] = youtubeTrailer;
    data['episode_run_time'] = episodeRunTime;
    data['category_id'] = categoryId;
    data['category_ids'] = categoryIds;
    return data;
  }
}

class Episode {
  String? id;
  int? episodeNum;
  String? title;
  String? containerExtension;
  EpisodeInfo? info;
  String? customSid;
  String? added;
  int? season;
  String? directSource;

  Episode({
    this.id,
    this.episodeNum,
    this.title,
    this.containerExtension,
    this.info,
    this.customSid,
    this.added,
    this.season,
    this.directSource,
  });

  Episode.fromJson(Map<String, dynamic> json) {
    id = json['id']?.toString();
    episodeNum = json['episode_num'] is String
        ? int.tryParse(json['episode_num'])
        : json['episode_num'];
    title = json['title']?.toString();
    containerExtension = json['container_extension']?.toString();
    info = json['info'] != null ? EpisodeInfo.fromJson(json['info']) : null;
    customSid = json['custom_sid']?.toString();
    added = json['added']?.toString();
    season = json['season'] is String
        ? int.tryParse(json['season'])
        : json['season'];
    directSource = json['direct_source']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = this.id;
    data['episode_num'] = this.episodeNum;
    data['title'] = this.title;
    data['container_extension'] = this.containerExtension;
    if (this.info != null) {
      data['info'] = this.info!.toJson();
    }
    data['custom_sid'] = this.customSid;
    data['added'] = this.added;
    data['season'] = this.season;
    data['direct_source'] = this.directSource;
    return data;
  }
}

class EpisodeInfo {
  String? airDate;
  String? crew;
  dynamic rating;
  int? id;
  String? movieImage;
  int? durationSecs;
  String? duration;
  VideoMetadata? video;
  AudioMetadata? audio;
  int? bitrate;

  EpisodeInfo({
    this.airDate,
    this.crew,
    this.rating,
    this.id,
    this.movieImage,
    this.durationSecs,
    this.duration,
    this.video,
    this.audio,
    this.bitrate,
  });

  EpisodeInfo.fromJson(Map<String, dynamic> json) {
    airDate = json['air_date']?.toString();
    crew = json['crew']?.toString();
    rating = json['rating'];
    id = json['id'] is String ? int.tryParse(json['id']) : json['id'];
    movieImage = json['movie_image']?.toString();
    durationSecs = json['duration_secs'] is String
        ? int.tryParse(json['duration_secs'])
        : json['duration_secs'];
    duration = json['duration']?.toString();
    video = json['video'] != null
        ? VideoMetadata.fromJson(json['video'])
        : null;
    audio = json['audio'] != null
        ? AudioMetadata.fromJson(json['audio'])
        : null;
    bitrate = json['bitrate'] is String
        ? int.tryParse(json['bitrate'])
        : json['bitrate'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['air_date'] = this.airDate;
    data['crew'] = this.crew;
    data['rating'] = this.rating;
    data['id'] = this.id;
    data['movie_image'] = this.movieImage;
    data['duration_secs'] = this.durationSecs;
    data['duration'] = this.duration;
    if (this.video != null) {
      data['video'] = this.video!.toJson();
    }
    if (this.audio != null) {
      data['audio'] = this.audio!.toJson();
    }
    data['bitrate'] = this.bitrate;
    return data;
  }
}

class VideoMetadata {
  int? index;
  String? codecName;
  String? codecLongName;
  String? profile;
  String? codecType;
  int? width;
  int? height;
  String? duration;
  String? bitRate;

  VideoMetadata({
    this.index,
    this.codecName,
    this.codecLongName,
    this.profile,
    this.codecType,
    this.width,
    this.height,
    this.duration,
    this.bitRate,
  });

  VideoMetadata.fromJson(Map<String, dynamic> json) {
    index = json['index'] is String
        ? int.tryParse(json['index'])
        : json['index'];
    codecName = json['codec_name']?.toString();
    codecLongName = json['codec_long_name']?.toString();
    profile = json['profile']?.toString();
    codecType = json['codec_type']?.toString();
    width = json['width'] is String
        ? int.tryParse(json['width'])
        : json['width'];
    height = json['height'] is String
        ? int.tryParse(json['height'])
        : json['height'];
    if (json['tags'] != null) {
      duration = json['tags']['DURATION']?.toString();
      bitRate = json['tags']['BPS']?.toString();
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['index'] = this.index;
    data['codec_name'] = this.codecName;
    data['codec_long_name'] = this.codecLongName;
    data['profile'] = this.profile;
    data['codec_type'] = this.codecType;
    data['width'] = this.width;
    data['height'] = this.height;
    return data;
  }
}

class AudioMetadata {
  int? index;
  String? codecName;
  String? codecLongName;
  String? codecType;
  String? sampleFmt;
  String? sampleRate;
  int? channels;
  String? channelLayout;
  String? language;

  AudioMetadata({
    this.index,
    this.codecName,
    this.codecLongName,
    this.codecType,
    this.sampleFmt,
    this.sampleRate,
    this.channels,
    this.channelLayout,
    this.language,
  });

  AudioMetadata.fromJson(Map<String, dynamic> json) {
    index = json['index'] is String
        ? int.tryParse(json['index'])
        : json['index'];
    codecName = json['codec_name']?.toString();
    codecLongName = json['codec_long_name']?.toString();
    codecType = json['codec_type']?.toString();
    sampleFmt = json['sample_fmt']?.toString();
    sampleRate = json['sample_rate']?.toString();
    channels = json['channels'] is String
        ? int.tryParse(json['channels'])
        : json['channels'];
    channelLayout = json['channel_layout']?.toString();
    if (json['tags'] != null) {
      language = json['tags']['language']?.toString();
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['index'] = this.index;
    data['codec_name'] = this.codecName;
    data['codec_long_name'] = this.codecLongName;
    data['codec_type'] = this.codecType;
    data['sample_fmt'] = this.sampleFmt;
    data['sample_rate'] = this.sampleRate;
    data['channels'] = this.channels;
    data['channel_layout'] = this.channelLayout;
    return data;
  }
}

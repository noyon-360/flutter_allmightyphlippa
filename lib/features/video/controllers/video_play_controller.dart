import 'package:flutter/material.dart';
import 'package:flutter_almightyflippa/features/playlist/models/server_request_model.dart';
import 'package:flutx_core/core/debug_print.dart';
import 'package:get/get.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import 'dart:async';
import '../../downloads/controllers/download_controller.dart';
import '../../movie/controllers/movie_controller.dart';
import '../../profile/controller/profile_controller.dart';
import '../../series/controllers/series_controller.dart';
import '../../series/models/single_series_response_model.dart';
import '../../../core/services/auth_storage_service.dart';
import '../../../core/services/watch_history_service.dart';
import '../repositories/video_status_repo.dart';
import '../models/video_status_request_model.dart';

class VideoPlayController extends GetxController {
  MovieController get movieCtrl => Get.find<MovieController>();
  SeriesController get seriesCtrl => Get.find<SeriesController>();
  VideoStatusRepo get videoStatusRepo => Get.find<VideoStatusRepo>();
  ProfileController get profileCtrl => Get.find<ProfileController>();

  late final Player player;
  late final VideoController videoController;

  final isVideoInitialized = false.obs;
  final hasStartedPlaying = false.obs;
  final currentType = Rxn<ServerType>();
  final isLoading = false.obs;

  // Track the current episode for series
  final currentEpisode = Rxn<Episode>();
  // Track which season's episode folder is currently open in the episode list
  final selectedSeason = Rxn<String>();
  final isLoved = false.obs;

  final playbackSpeed = 1.0.obs;
  final availableSpeeds = [0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];

  final currentVideoTrack = Rxn<VideoTrack>();
  final availableVideoTracks = <VideoTrack>[].obs;

  final currentAudioTrack = Rxn<AudioTrack>();
  final availableAudioTracks = <AudioTrack>[].obs;

  final currentSubtitleTrack = Rxn<SubtitleTrack>();
  final availableSubtitleTracks = <SubtitleTrack>[].obs;
  final isSubtitleEnabled = true.obs;

  StreamSubscription? _positionSubscription;
  StreamSubscription? _tracksSubscription;
  StreamSubscription? _errorSubscription;
  Duration _lastUpdatePosition = Duration.zero;
  final _updateInterval = const Duration(seconds: 10);
  String? _currentVideoId;
  String? _currentVideoType;
  String? _currentPlayUrl;

  /// The URL currently loaded into the player — used by iOS PiP fallback.
  String? get currentPlayUrl => _currentPlayUrl;

  String? get currentVideoId => _currentVideoId;
  String? get currentVideoType => _currentVideoType;

  String get currentExt {
    if (_currentPlayUrl == null) return 'mkv';
    final path = Uri.tryParse(_currentPlayUrl!)?.path ?? '';
    final dot = path.lastIndexOf('.');
    return (dot >= 0 && dot < path.length - 1) ? path.substring(dot + 1) : 'mkv';
  }

  String? get currentThumbnail {
    if (_currentVideoType == 'movie') {
      return movieCtrl.movie.value?.streamData.info.movieImage;
    } else if (_currentVideoType == 'series') {
      return seriesCtrl.singleSeries.value?.data?.info?.cover;
    }
    return null;
  }

  /// Current playback position in seconds — used by iOS PiP to seek on resume.
  double get currentPositionSeconds =>
      player.state.position.inMilliseconds / 1000.0;

  bool get isSubscribed {
    final user = profileCtrl.userProfile.value;
    return user?.subscriptionStatus == 'active' || user?.plan == 'premium';
  }

  @override
  void onInit() {
    super.onInit();
    player = Player();
    videoController = VideoController(player);
    _setupTracksListener();
    _errorSubscription = player.stream.error.listen((error) {
      DPrint.error("Player error for url $_currentPlayUrl: $error");
      // Get.snackbar('Playback Error', 'Failed to play this video. Please try again later.');
    });
  }

  void _setupTracksListener() {
    _tracksSubscription = player.stream.tracks.listen((tracks) {
      availableVideoTracks.value = tracks.video;
      availableAudioTracks.value = tracks.audio;
      availableSubtitleTracks.value = tracks.subtitle;

      // Initialize current tracks if not set
      if (currentVideoTrack.value == null && tracks.video.isNotEmpty) {
        currentVideoTrack.value = player.state.track.video;
      }
      if (currentAudioTrack.value == null && tracks.audio.isNotEmpty) {
        currentAudioTrack.value = player.state.track.audio;
      }
      if (currentSubtitleTrack.value == null && tracks.subtitle.isNotEmpty) {
        currentSubtitleTrack.value = player.state.track.subtitle;
      }
    });
  }

  void setPlaybackSpeed(double speed) {
    player.setRate(speed);
    playbackSpeed.value = speed;
  }

  void setVideoTrack(VideoTrack track) {
    player.setVideoTrack(track);
    currentVideoTrack.value = track;
  }

  /// Quality badge label derived from the actual decoded video track, not
  /// from text in the title or pre-fetched metadata. Only returns a value
  /// once the video is confirmed loaded and rendering, so the badge never
  /// appears prematurely.
  String? get qualityLabel {
    if (!isVideoInitialized.value) return null;
    final height = currentVideoTrack.value?.h;
    if (height == null || height <= 0) return null;
    if (height >= 2160) return '4K';
    if (height >= 1080) return 'FHD';
    if (height >= 720) return 'HD';
    return null;
  }

  void setAudioTrack(AudioTrack track) {
    player.setAudioTrack(track);
    currentAudioTrack.value = track;
  }

  void setSubtitleTrack(SubtitleTrack track) {
    player.setSubtitleTrack(track);
    currentSubtitleTrack.value = track;
    isSubtitleEnabled.value = track != SubtitleTrack.no();
  }

  void toggleSubtitle(bool enabled) {
    if (enabled) {
      // Try to restore previous or first available subtitle
      if (availableSubtitleTracks.isNotEmpty) {
        final track = currentSubtitleTrack.value != SubtitleTrack.no()
            ? currentSubtitleTrack.value!
            : availableSubtitleTracks.firstWhere(
                (t) => t != SubtitleTrack.no(),
                orElse: () => availableSubtitleTracks.first,
              );
        setSubtitleTrack(track);
      }
    } else {
      player.setSubtitleTrack(SubtitleTrack.no());
      isSubtitleEnabled.value = false;
    }
  }

  String get title {
    if (currentType.value == ServerType.movies) {
      return movieCtrl.movie.value?.streamData.info.name ?? '';
    } else if (currentType.value == ServerType.series) {
      if (currentEpisode.value != null) {
        return currentEpisode.value!.title ??
            'Episode ${currentEpisode.value!.episodeNum}';
      }
      return seriesCtrl.singleSeries.value?.data?.info?.name ?? '';
    }
    return '';
  }

  String get subTitle {
    if (currentType.value == ServerType.movies) {
      final movie = movieCtrl.movie.value;
      if (movie == null) return '';
      return '${movie.streamData.movieData.added} | Movie | ${movie.streamData.info.duration}';
    } else if (currentType.value == ServerType.series) {
      final series = seriesCtrl.singleSeries.value;
      if (series == null) return '';
      if (currentEpisode.value != null) {
        return 'S${currentEpisode.value!.season} E${currentEpisode.value!.episodeNum} | ${currentEpisode.value!.info?.duration ?? ''}';
      }
      return '${series.data?.info?.releaseDate ?? ''} | Series | ${series.data?.info?.rating ?? ''}/10';
    }
    return '';
  }

  String get description {
    if (currentType.value == ServerType.movies) {
      final movie = movieCtrl.movie.value;
      if (movie == null) return '';
      return movie.streamData.info.description.isNotEmpty
          ? movie.streamData.info.description
          : (movie.streamData.info.plot.isNotEmpty
                ? movie.streamData.info.plot
                : 'No description available');
    } else if (currentType.value == ServerType.series) {
      final series = seriesCtrl.singleSeries.value;
      if (series == null) return '';
      return series.data?.info?.plot ?? 'No description available';
    }
    return '';
  }

  @override
  void onClose() {
    _positionSubscription?.cancel();
    _tracksSubscription?.cancel();
    _errorSubscription?.cancel();
    _syncVideoStatus().then((_) {
      // Refresh the watch history globally after the final sync
      if (Get.isRegistered<WatchHistoryService>()) {
        Get.find<WatchHistoryService>().refreshList();
      }
    });
    player.dispose();
    super.onClose();
  }

  Future<void> initializeVideo({
    required ServerType type,
    required int streamId,
    bool autoPlay = true,
    String? localPath,
  }) async {
    // Reset previous state
    isLoading.value = true;
    isVideoInitialized.value = false;
    currentType.value = type;
    currentEpisode.value = null;
    hasStartedPlaying.value = autoPlay;

    // Reset settings
    playbackSpeed.value = 1.0;
    currentVideoTrack.value = null;
    availableVideoTracks.value = [];
    currentAudioTrack.value = null;
    availableAudioTracks.value = [];
    currentSubtitleTrack.value = null;
    availableSubtitleTracks.value = [];
    isSubtitleEnabled.value = true;

    try {
      if (type == ServerType.movies) {
        await _loadMovie(streamId, autoPlay: autoPlay, localPath: localPath);
      } else if (type == ServerType.series) {
        await _loadSeries(streamId, autoPlay: autoPlay);
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadMovie(int streamId, {bool autoPlay = true, String? localPath}) async {
    _currentVideoId = streamId.toString();
    _currentVideoType = 'movie';

    // Clear the previously loaded movie's detail state so the UI can't show
    // stale title/description/etc. while the new movie's data is in flight,
    // or indefinitely if this fetch fails.
    movieCtrl.movie.value = null;

    // Play from local file if available (offline download)
    if (localPath != null) {
      await _initializePlayer(localPath, autoPlay: autoPlay);
      return;
    }

    await movieCtrl.getMovieDetails(streamId: streamId);
    final movie = movieCtrl.movie.value;
    if (movie != null && movie.playUrl.isNotEmpty) {
      await _initializePlayer(movie.playUrl, autoPlay: autoPlay);
    } else {
      DPrint.error("No playUrl returned for movie streamId: $streamId");
      Get.snackbar('Playback Error', 'Could not get a playable link for this movie.');
    }
  }

  /// Season keys ("1", "2", ...) sorted numerically rather than by JSON/insertion order.
  List<String> sortedSeasonKeys(Map<String, List<dynamic>>? episodesMap) {
    if (episodesMap == null) return [];
    final keys = episodesMap.keys.toList();
    keys.sort((a, b) {
      final aNum = int.tryParse(a);
      final bNum = int.tryParse(b);
      if (aNum != null && bNum != null) return aNum.compareTo(bNum);
      return a.compareTo(b);
    });
    return keys;
  }

  /// Used by the "Watch Now" button and the play overlay to start a series
  /// from its first episode. Surfaces feedback instead of silently doing
  /// nothing when a series has no playable episode data.
  void playFirstAvailableEpisode() {
    final firstEpisode = seriesCtrl
        .singleSeries
        .value
        ?.data
        ?.episodes
        ?.values
        .firstOrNull
        ?.firstOrNull;
    if (firstEpisode != null) {
      playEpisode(firstEpisode);
    } else {
      Get.snackbar(
        'No Episodes Available',
        'This series has no playable episodes right now.',
      );
    }
  }

  void changeSeason(String seasonKey) {
    selectedSeason.value = seasonKey;
  }

  Future<void> _loadSeries(int streamId, {bool autoPlay = true}) async {
    // Clear the previously loaded series' detail state so the UI can't show
    // stale title/description/episodes while the new series' data is in
    // flight, or indefinitely if this fetch fails.
    seriesCtrl.singleSeries.value = null;
    selectedSeason.value = null;

    // Fetch details
    await seriesCtrl.getSeriesDetails(streamId: streamId);

    final series = seriesCtrl.singleSeries.value;
    final episodesMap = series?.data?.episodes;
    final seasonKeys = sortedSeasonKeys(episodesMap);
    if (seasonKeys.isNotEmpty) {
      selectedSeason.value = seasonKeys.first;
    }

    if (!autoPlay) return;

    if (episodesMap != null && seasonKeys.isNotEmpty) {
      final firstSeasonEpisodes = episodesMap[seasonKeys.first];
      if (firstSeasonEpisodes != null && firstSeasonEpisodes.isNotEmpty) {
        playEpisode(firstSeasonEpisodes.first);
      }
    }
  }

  Future<void> playEpisode(Episode episode, {bool autoPlay = true}) async {
    hasStartedPlaying.value = true;
    currentEpisode.value = episode;
    isVideoInitialized.value = false;

    // Reset settings
    playbackSpeed.value = 1.0;
    currentVideoTrack.value = null;
    availableVideoTracks.value = [];
    currentAudioTrack.value = null;
    availableAudioTracks.value = [];
    currentSubtitleTrack.value = null;
    availableSubtitleTracks.value = [];
    isSubtitleEnabled.value = true;

    try {
      _currentVideoId = episode.id.toString();
      _currentVideoType = 'series';

      // Play from local file if downloaded
      if (Get.isRegistered<DownloadController>()) {
        final localFile = DownloadController.to.localPath(_currentVideoId!, 'series');
        if (localFile != null) {
          await _initializePlayer(localFile, autoPlay: autoPlay);
          return;
        }
      }

      final storage = AuthStorageService();
      final playlistData = await storage.getPlaylistData();
      final urlObject = Uri.parse(playlistData.url);
      final fileExt = episode.containerExtension != null && episode.containerExtension!.isNotEmpty
          ? episode.containerExtension
          : 'mkv';

      final playUrl = urlObject.replace(
        path: '/series/${playlistData.username}/${playlistData.password}/${episode.id}.$fileExt'
      ).toString();

      await _initializePlayer(playUrl, autoPlay: autoPlay);
    } catch (e) {
      debugPrint('Error playing episode: $e');
      // Get.snackbar('Error', 'Failed to play episode');
    }
  }

  Future<void> _initializePlayer(String videoUrl, {bool autoPlay = true}) async {
    _currentPlayUrl = videoUrl;
    try {
      // 1. Fetch resume position if we have video info
      Duration startPosition = Duration.zero;
      if (_currentVideoId != null) {
        // Fetch watch history to check for resume position as requested by user
        final result = await videoStatusRepo.getVideoStatus(_currentVideoId!);
        if (result.isRight()) {
          final historySuccess = result.getOrElse(() => throw Exception());
          final historyItem = historySuccess.data;

          // Find the current video in history list
          // final historyItem = historyList.firstWhereOrNull(
          //   (item) => item.videoId == _currentVideoId,
          // );

          isLoved.value = historyItem.isLoved;

          if (!historyItem.isCompleted && historyItem.currentTime > 0) {
            // Check if the video is nearly at the end
            // If remaining time < 10 seconds OR progress > 95%, start from beginning
            final remainingSeconds =
                historyItem.duration - historyItem.currentTime;
            final progressPercentage = historyItem.duration > 0
                ? (historyItem.currentTime / historyItem.duration)
                : 0.0;

            if (remainingSeconds < 10 || progressPercentage > 0.95) {
              startPosition = Duration.zero;
              DPrint.log(
                "Video nearly finished, starting from beginning. Remaining: $remainingSeconds, Progress: $progressPercentage",
              );
            } else {
              startPosition = Duration(
                seconds: historyItem.currentTime.toInt(),
              );
              DPrint.log("Resuming from saved position: $startPosition");
            }
          }
        } else {
          startPosition = Duration.zero;
          isLoved.value = false;
        }
      }

      // 2. Open Player (start paused to allow seeking)
      if (!isSubscribed) {
        // Limit resolution for non-subscribed users
        try {
          await (player.platform as dynamic).setProperty('video-max-height', '480');
          DPrint.log("Non-subscribed user: limiting quality to 480p");
        } catch (e) {
          DPrint.log("Error setting quality limit: $e");
        }
      } else {
        // Reset quality for subscribed users
        try {
          await (player.platform as dynamic).setProperty('video-max-height', '0');
          DPrint.log("Subscribed user: full quality enabled");
        } catch (e) {
          DPrint.log("Error resetting quality limit: $e");
        }
      }

      DPrint.log("Opening video URL: $videoUrl");
      await player.open(Media(videoUrl), play: false);

      if (startPosition > Duration.zero) {
        // Wait for player to be ready (has duration)
        final Completer<void> ready = Completer();
        final sub = player.stream.duration.listen((d) {
          if (d > Duration.zero && !ready.isCompleted) {
            ready.complete();
          }
        });

        // timeout after 10 seconds if it never gets duration
        await ready.future.timeout(const Duration(seconds: 10)).catchError((_) {
          DPrint.log("Timed out waiting for duration");
        });
        await sub.cancel();

        // Seek to the start position
        await player.seek(startPosition);
        DPrint.log("Seeked to: $startPosition");

        // Small additional delay to ensure seek is processed
        await Future.delayed(const Duration(milliseconds: 200));
      }

      // 3. Start playback
      if (autoPlay) {
        await player.play();
      }

      isVideoInitialized.value = true;
      _startPositionListener();
    } catch (e) {
      debugPrint('Error initializing video player: $e');
      // Get.snackbar('Error', 'Failed to load video');
    }
  }

  Future<void> toggleFavorite() async {
    if (_currentVideoId == null || _currentVideoType == null) return;

    final result = await videoStatusRepo.updateVideoStatus(
      UpdateVideoStatusRequest(
        title: title,
        videoId: _currentVideoId!,
        videoType: _currentVideoType!,
        isLoved: !isLoved.value,
      ),
    );
    if (result.isRight()) {
      isLoved.value = !isLoved.value;
      if (Get.isRegistered<WatchHistoryService>()) {
        Get.find<WatchHistoryService>().refreshList();
      }
    }
  }

  void _startPositionListener() {
    _positionSubscription?.cancel();
    _positionSubscription = player.stream.position.listen((position) {
      if ((position - _lastUpdatePosition).abs() > _updateInterval) {
        _syncVideoStatus();
        _lastUpdatePosition = position;
      }
    });
  }

  Future<void> _syncVideoStatus() async {
    if (_currentVideoId == null || _currentVideoType == null) return;

    final position = player.state.position;
    final duration = player.state.duration;

    if (duration == Duration.zero) return;
    
    final currentTimeSec = position.inSeconds.toDouble();
    final durationSec = duration.inSeconds.toDouble();

    // Optimistically update progress in UI immediately
    if (Get.isRegistered<WatchHistoryService>()) {
      Get.find<WatchHistoryService>().updateProgressGlobally(
        videoId: _currentVideoId!,
        newTime: currentTimeSec,
        duration: durationSec,
      );
    }

    await videoStatusRepo.updateVideoStatus(
      UpdateVideoStatusRequest(
        title: title,
        videoId: _currentVideoId!,
        videoType: _currentVideoType!,
        currentTime: currentTimeSec,
        duration: durationSec,
        seasonNumber: currentEpisode.value?.season,
        episodeNumber: currentEpisode.value?.episodeNum,
        thumbnail: _getThumbnail(),
      ),
    );
  }

  String? _getThumbnail() {
    if (_currentVideoType == 'movie') {
      return movieCtrl.movie.value?.streamData.info.movieImage;
    } else if (_currentVideoType == 'series') {
      return seriesCtrl.singleSeries.value?.data?.info?.cover;
    }
    return null;
  }
}

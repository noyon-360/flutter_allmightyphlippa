import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../../../core/services/watch_history_service.dart';
import '../../profile/controller/profile_controller.dart';
import '../../tv/repositories/live_tv_repo.dart';
import '../models/video_status_request_model.dart';
import '../repositories/video_status_repo.dart';

class LiveVideoPlayController extends GetxController {
  final _liveTvRepo = Get.find<LiveTvRepo>();
  final _profileCtrl = Get.find<ProfileController>();
  final _videoStatusRepo = Get.find<VideoStatusRepo>();

  // media_kit (like Movies/Series) rather than video_player: it can list and
  // select the subtitle and audio tracks a live stream carries.
  late final Player player;
  late final VideoController videoController;

  final isVideoInitialized = false.obs;
  final isLoading = false.obs;
  final errorMessage = Rxn<String>();

  final isPlaying = false.obs;
  final isBuffering = false.obs;

  final availableAudioTracks = <AudioTrack>[].obs;
  final currentAudioTrack = Rxn<AudioTrack>();
  final availableSubtitleTracks = <SubtitleTrack>[].obs;
  final currentSubtitleTrack = Rxn<SubtitleTrack>();

  final _subscriptions = <StreamSubscription>[];

  /// Completes the wait in [initializeLiveVideo] as soon as the stream either
  /// starts rendering or reports an error. Null when nothing is waiting.
  Completer<bool>? _startup;

  /// The URL of the stream currently being played (used for casting).
  String? _currentPlayUrl;
  String? get currentPlayUrl => _currentPlayUrl;

  bool get isSubscribed {
    final user = _profileCtrl.userProfile.value;
    return user?.subscriptionStatus == 'active' || user?.plan == 'premium';
  }

  @override
  void onInit() {
    super.onInit();
    player = Player();
    videoController = VideoController(player);

    _subscriptions.addAll([
      player.stream.playing.listen((v) => isPlaying.value = v),
      player.stream.buffering.listen((v) => isBuffering.value = v),
      player.stream.tracks.listen((tracks) {
        availableAudioTracks.assignAll(tracks.audio);
        availableSubtitleTracks.assignAll(tracks.subtitle);
      }),
      player.stream.track.listen((track) {
        currentAudioTrack.value = track.audio;
        currentSubtitleTrack.value = track.subtitle;
      }),
      // Playback has really started once a picture (or, for audio-only
      // channels, sound) is coming through — not merely when play was asked.
      player.stream.videoParams.listen((params) {
        final startup = _startup;
        if ((params.w ?? 0) > 0 && startup != null && !startup.isCompleted) {
          startup.complete(true);
        }
      }),
      player.stream.error.listen(_onPlayerError),
    ]);
  }

  @override
  void onClose() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    player.dispose();
    super.onClose();
  }

  /// mpv also reports problems that don't stop playback (no audio output on a
  /// simulator, an unknown option) — those must not read as "stream failed".
  bool _isBenign(String error) {
    final msg = error.toLowerCase();
    return msg.contains('audio device') ||
        msg.contains('no sound') ||
        msg.contains('property not found');
  }

  void _onPlayerError(String error) {
    debugPrint('Live player error: $error');
    if (_isBenign(error)) return;
    // Only a failure to start is surfaced; once playing, mpv reports and
    // recovers from transient hiccups on its own.
    final startup = _startup;
    if (startup != null && !startup.isCompleted) {
      errorMessage.value = _friendlyError(error);
      startup.complete(false);
    }
  }

  /// Turns a raw player/network error into something worth showing.
  String _friendlyError(String raw) {
    final msg = raw.toLowerCase();
    if (msg.contains('socketexception') ||
        msg.contains('failed host lookup') ||
        msg.contains('network')) {
      return 'No internet connection.\nPlease check your network and try again.';
    }
    if (msg.contains('404') || msg.contains('not found')) {
      return 'Channel stream not found.\nThe channel may be temporarily unavailable.';
    }
    if (msg.contains('521') ||
        msg.contains('522') ||
        msg.contains('520') ||
        msg.contains('connection refused')) {
      return 'The stream server is currently down.\nPlease try again later.';
    }
    return 'Failed to load stream.\nThe server may be temporarily unavailable.';
  }

  // ─── Tracks ──────────────────────────────────────────────────────────────

  /// Whether the stream carries real subtitle/caption tracks (beyond the
  /// built-in "off"/"auto" entries every stream reports).
  bool get hasSubtitleTracks => availableSubtitleTracks.any(
    (t) => t != SubtitleTrack.no() && t != SubtitleTrack.auto(),
  );

  /// Whether there's a real choice of audio (more than one actual track).
  bool get hasMultipleAudioTracks =>
      availableAudioTracks
          .where((t) => t != AudioTrack.no() && t != AudioTrack.auto())
          .length >
      1;

  void setSubtitleTrack(SubtitleTrack track) {
    player.setSubtitleTrack(track);
    currentSubtitleTrack.value = track;
  }

  void setAudioTrack(AudioTrack track) {
    player.setAudioTrack(track);
    currentAudioTrack.value = track;
  }

  Future<void> initializeLiveVideo({
    required int streamId,
    String channelName = '',
    String channelLogo = '',
  }) async {
    isVideoInitialized.value = false;
    errorMessage.value = null;
    isLoading.value = true;

    // Stop whatever was playing before (a retry reuses the same player).
    await player.stop();

    try {
      final result = await _liveTvRepo.getSingleLiveTV(streamId: streamId);

      await result.fold(
        (fail) async {
          debugPrint('Error fetching live TV URL: ${fail.message}');
          errorMessage.value =
              'Could not reach the server.\nPlease check your connection and try again.';
        },
        (success) async {
          String playUrl = success.data.playUrl;

          if (!isSubscribed && playUrl.isNotEmpty) {
            final separator = playUrl.contains('?') ? '&' : '?';
            playUrl = '$playUrl${separator}quality=low';
            debugPrint('Non-subscribed user: requesting low quality stream');
          }

          debugPrint('Live TV Play URL: $playUrl');
          _currentPlayUrl = playUrl;

          if (playUrl.isEmpty) {
            errorMessage.value = 'Stream URL is unavailable for this channel.';
            return;
          }

          _startup = Completer<bool>();
          await player.open(Media(playUrl), play: true);
          // Captions are opt-in: start with them off even if the stream
          // flags one as default, and let the viewer turn them on.
          await player.setSubtitleTrack(SubtitleTrack.no());

          final started = await _startup!.future.timeout(
            const Duration(seconds: 25),
            onTimeout: () {
              // Audio-only channels never report a picture size; if sound is
              // flowing, that's playback too.
              final soundOnly = player.state.playing && !player.state.buffering;
              if (!soundOnly) {
                errorMessage.value ??=
                    'Failed to load stream.\nThe server may be temporarily unavailable.';
              }
              return soundOnly;
            },
          );
          _startup = null;
          if (!started) return;

          isVideoInitialized.value = true;

          // Record this channel in watch history so it can show up under
          // "Live TV History" — there's no meaningful resume position for a
          // live stream, so this is purely a "recently watched" marker.
          _videoStatusRepo
              .updateVideoStatus(
                UpdateVideoStatusRequest(
                  title: channelName.isNotEmpty ? channelName : 'Live TV',
                  videoId: streamId.toString(),
                  videoType: 'live',
                  thumbnail: channelLogo.isNotEmpty ? channelLogo : null,
                ),
              )
              .then((result) {
                if (result.isRight() &&
                    Get.isRegistered<WatchHistoryService>()) {
                  Get.find<WatchHistoryService>().refreshList();
                }
              });
        },
      );
    } catch (e) {
      debugPrint('Error initializing live video: $e');
      errorMessage.value = _friendlyError(e.toString());
    } finally {
      _startup = null;
      isLoading.value = false;
    }
  }
}

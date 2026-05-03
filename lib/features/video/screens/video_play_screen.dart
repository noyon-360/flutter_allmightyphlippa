import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_almightyflippa/core/common/widgets/tv_focus_wrapper.dart';

import 'package:flutter_almightyflippa/features/playlist/models/server_request_model.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '/core/constants/app_colors.dart';
import 'package:get/get.dart';

import '../controllers/video_play_controller.dart';
import 'package:floating/floating.dart';

class VideoPlayScreen extends StatefulWidget {
  final int streamId;
  final ServerType type;
  const VideoPlayScreen({
    super.key,
    required this.streamId,
    required this.type,
  });

  @override
  State<VideoPlayScreen> createState() => _VideoPlayScreenState();
}

class _VideoPlayScreenState extends State<VideoPlayScreen>
    with WidgetsBindingObserver {
  final controller = Get.put(VideoPlayController());
  final ScrollController _scrollController = ScrollController();

  Floating? pip;
  bool isPipAvailable = false;
  PiPStatus _pipStatus = PiPStatus.disabled;
  StreamSubscription<PiPStatus>? _pipSubscription;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addObserver(this);
    if (Platform.isAndroid) {
      pip = Floating();
      _checkPipAvailability();
      try {
        _pipSubscription = pip?.pipStatusStream.listen(
          (status) {
            if (mounted) {
              setState(() {
                _pipStatus = status;
              });
            }
          },
          onError: (e) {
            debugPrint('PiP stream error: $e');
          },
        );
      } catch (e) {
        debugPrint('Failed to initialize PiP stream: $e');
      }
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.initializeVideo(type: widget.type, streamId: widget.streamId);
    });
  }

  Future<void> _checkPipAvailability() async {
    if (pip == null) return;
    try {
      isPipAvailable = await pip!.isPipAvailable;
    } catch (e) {
      debugPrint('PiP availability check error: $e');
      isPipAvailable = false;
    }
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if ((state == AppLifecycleState.hidden ||
            state == AppLifecycleState.paused) &&
        isPipAvailable &&
        pip != null &&
        controller.isVideoInitialized.value) {
      pip!.enable(const ImmediatePiP(aspectRatio: Rational.landscape()));
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (controller.currentType.value == ServerType.movies) {
        controller.movieCtrl.getMovies(isLoadMore: true);
      } else if (controller.currentType.value == ServerType.series) {
        controller.seriesCtrl.getSeries(isLoadMore: true);
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _pipSubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    // Explicitly delete the controller to ensure player is disposed and video stops.
    Get.delete<VideoPlayController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Temporarily disabled PiPSwitcher to debug blank screen issue.
    // We will return only the main content for now.
    return _buildMainContent(context);
  }

  Widget _buildMainContent(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlack,
      body: SafeArea(
        child: Obx(() {
          if (controller.isLoading.value) {
            return const Center(
              child: SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(color: AppColors.red),
              ),
            );
          }

          // Access reactive data here to ensure this Obx rebuilds when lists change
          final movies = controller.movieCtrl.movies;
          final series = controller.seriesCtrl.series;
          final singleSeries = controller.seriesCtrl.singleSeries.value;

          return LayoutBuilder(
            builder: (context, constraints) {
              return Column(
                children: [
                  // Fixed Video Player
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: constraints.maxHeight,
                    ),
                    child: Container(
                      width: MediaQuery.of(context).size.width,
                      color: Colors.black,
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: Stack(
                          children: [
                            MaterialVideoControlsTheme(
                              normal: const MaterialVideoControlsThemeData(
                                buttonBarHeight: 48.0,
                                controlsHoverDuration: Duration(seconds: 10),
                              ),
                              fullscreen:
                                  const MaterialVideoControlsThemeData(
                                controlsHoverDuration: Duration(seconds: 10),
                              ),
                              child: Focus(
                                autofocus: true,
                                child: Video(
                                  controller: controller.videoController,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                ),
                              ),
                            ),
                            Obx(() {
                              if (!controller.isVideoInitialized.value) {
                                return const Positioned.fill(
                                  child: Center(
                                    child: SizedBox(
                                      width: 32,
                                      height: 32,
                                      child: CircularProgressIndicator(
                                        color: AppColors.red,
                                        strokeWidth: 3,
                                      ),
                                    ),
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            }),
                            if (_pipStatus != PiPStatus.enabled) ...[
                              Positioned(
                                top: 10,
                                left: 10,
                                child: TvFocusWrapper(
                                  onTap: () => Navigator.pop(context),
                                  child: const BackButton(color: Colors.white),
                                ),
                              ),
                              Positioned(
                                top: 10,
                                right: 10,
                                child: Row(
                                  children: [
                                    if (isPipAvailable)
                                      TvFocusWrapper(
                                        onTap: () {
                                          if (pip != null) {
                                            pip!.enable(
                                              const ImmediatePiP(
                                                aspectRatio:
                                                    Rational.landscape(),
                                              ),
                                            );
                                          }
                                        },
                                        child: const Padding(
                                          padding: EdgeInsets.all(8.0),
                                          child: Icon(
                                            Icons.picture_in_picture_alt,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    TvFocusWrapper(
                                      onTap: () {
                                        _showSettingsDialog(context);
                                      },
                                      child: const Padding(
                                        padding: EdgeInsets.all(8.0),
                                        child: Icon(
                                          Icons.settings,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Scrollable Content
                  if (_pipStatus != PiPStatus.enabled)
                    Expanded(
                      child: CustomScrollView(
                        controller: _scrollController,
                        slivers: [
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    controller.title,
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    controller.subTitle,
                                    style: const TextStyle(
                                      color: AppColors.primaryGray,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    controller.description,
                                    style: const TextStyle(
                                      color: AppColors.primaryGray,
                                      fontSize: 14,
                                      height: 1.5,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      TvFocusWrapper(
                                        onTap: () =>
                                            controller.toggleFavorite(),
                                        child: Column(
                                          children: [
                                            Obx(() {
                                              return Icon(
                                                controller.isLoved.value
                                                    ? Icons.favorite
                                                    : Icons.favorite_border,
                                                color: Colors.white,
                                                size: 30,
                                              );
                                            }),
                                            const Text(
                                              "Favourite",
                                              style: TextStyle(
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Related List or Episodes
                          if (controller.currentType.value == ServerType.movies)
                            _buildMovieList(context, movies)
                          else if (controller.currentType.value ==
                              ServerType.series) ...[
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                  vertical: 8.0,
                                ),
                                child: Text(
                                  'Episodes',
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(
                                        color: AppColors.primaryWhite,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ),
                            ),
                            _buildEpisodeList(context, singleSeries),
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                  vertical: 16.0,
                                ),
                                child: Text(
                                  'Other Series',
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(
                                        color: AppColors.primaryWhite,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ),
                            ),
                            _buildSeriesList(context, series),
                          ],

                          // Loading Indicator for Pagination
                          SliverToBoxAdapter(
                            child: Obx(() {
                              final isMoreLoading =
                                  controller.currentType.value ==
                                      ServerType.movies
                                  ? controller.movieCtrl.isMoreLoading.value
                                  : controller.seriesCtrl.isMoreLoading.value;
                              if (isMoreLoading) {
                                return const Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      color: AppColors.red,
                                    ),
                                  ),
                                );
                              }
                              return const SizedBox(height: 20);
                            }),
                          ),
                        ],
                      ),
                    ),
                ],
              );
            },
          );
        }),
      ),
    );
  }

  Widget _buildMovieList(BuildContext context, List<dynamic> movies) {
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final movie = movies[index];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: TvFocusWrapper(
            onTap: () {
              controller.initializeVideo(
                type: ServerType.movies,
                streamId: movie.streamId,
              );
              _scrollController.animateTo(
                0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeIn,
              );
            },
            child: Row(
              children: [
                Container(
                  width: 100,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppColors.containerBgColor,
                    borderRadius: BorderRadius.circular(8),
                    image: movie.streamIcon.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(movie.streamIcon),
                            fit: BoxFit.cover,
                            onError: (_, __) {},
                          )
                        : null,
                  ),
                  child: movie.streamIcon.isEmpty
                      ? const Icon(Icons.movie, color: AppColors.iconColor)
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        movie.name,
                        style: const TextStyle(
                          color: AppColors.primaryWhite,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Movie | ${movie.added}',
                        style: const TextStyle(
                          color: AppColors.primaryGray,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }, childCount: movies.length),
    );
  }

  Widget _buildSeriesList(BuildContext context, List<dynamic> series) {
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final item = series[index];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: TvFocusWrapper(
            onTap: () {
              controller.initializeVideo(
                type: ServerType.series,
                streamId: item.seriesId!,
              );
              _scrollController.animateTo(
                0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeIn,
              );
            },
            child: Row(
              children: [
                Container(
                  width: 100,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppColors.containerBgColor,
                    borderRadius: BorderRadius.circular(8),
                    image: item.cover.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(item.cover),
                            fit: BoxFit.cover,
                            onError: (_, __) {},
                          )
                        : null,
                  ),
                  child: item.cover.isEmpty
                      ? const Icon(Icons.movie, color: AppColors.iconColor)
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name ?? "",
                        style: const TextStyle(
                          color: AppColors.primaryWhite,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Series',
                        style: TextStyle(
                          color: AppColors.primaryGray,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }, childCount: series.length),
    );
  }

  Widget _buildEpisodeList(BuildContext context, dynamic singleSeries) {
    final episodesMap = singleSeries?.data?.episodes;
    if (episodesMap == null || episodesMap.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            "No episodes found",
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    final List<dynamic> allEpisodes = [];
    episodesMap.forEach((season, episodes) {
      allEpisodes.addAll(episodes);
    });

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final episode = allEpisodes[index];
        final isPlaying = controller.currentEpisode.value?.id == episode.id;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: TvFocusWrapper(
            onTap: () {
              controller.playEpisode(episode);
              _scrollController.animateTo(
                0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeIn,
              );
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isPlaying
                    ? AppColors.red.withOpacity(0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: isPlaying
                    ? Border.all(color: AppColors.red.withOpacity(0.5))
                    : null,
              ),
              child: Row(
                children: [
                  Container(
                    width: 100,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.containerBgColor,
                      borderRadius: BorderRadius.circular(8),
                      image:
                          episode.info?.movieImage != null &&
                              episode.info!.movieImage!.isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(episode.info!.movieImage!),
                              fit: BoxFit.cover,
                              onError: (_, __) {},
                            )
                          : null,
                    ),
                    child:
                        episode.info?.movieImage == null ||
                            episode.info!.movieImage!.isEmpty
                        ? const Icon(
                            Icons.play_circle_outline,
                            color: AppColors.iconColor,
                          )
                        : isPlaying
                        ? const Center(
                            child: Icon(
                              Icons.play_arrow,
                              color: Colors.white,
                              size: 30,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          episode.title ?? "Episode ${episode.episodeNum}",
                          style: TextStyle(
                            color: isPlaying
                                ? AppColors.red
                                : AppColors.primaryWhite,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'S${episode.season} E${episode.episodeNum} | ${episode.info?.duration ?? ""}',
                          style: const TextStyle(
                            color: AppColors.primaryGray,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isPlaying)
                    const Icon(Icons.equalizer, color: AppColors.red, size: 20),
                ],
              ),
            ),
          ),
        );
      }, childCount: allEpisodes.length),
    );
  }

  void _showSettingsDialog(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      pageBuilder: (context, anim1, anim2) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.8,
              decoration: BoxDecoration(
                color: AppColors.containerBgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: const BoxDecoration(
                      color: Color(0xFF3D3D3D),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Settings",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TvFocusWrapper(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.black,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Content
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        // Quality
                        // _buildSettingRow(
                        //   label: "Quality",
                        //   value: Obx(() {
                        //     final currentTrack =
                        //         controller.currentVideoTrack.value;
                        //     if (currentTrack == null ||
                        //         currentTrack == VideoTrack.auto()) {
                        //       return const Text(
                        //         "Auto",
                        //         style: TextStyle(color: Colors.white),
                        //       );
                        //     }
                        //     return Text(
                        //       currentTrack.displayName,
                        //       style: const TextStyle(color: Colors.white),
                        //     );
                        //   }),
                        //   onTap: () {
                        //     Navigator.pop(context);
                        //     _showQualityDialog(context);
                        //   },
                        // ),
                        // const SizedBox(height: 16),
                        // Playback Speed
                        _buildSettingRow(
                          label: "Playback Speed",
                          value: Obx(() {
                            final speed = controller.playbackSpeed.value;
                            return Text(
                              speed == 1.0 ? "1" : speed.toString(),
                              style: const TextStyle(color: Colors.white),
                            );
                          }),
                          onTap: () {
                            Navigator.pop(context);
                            _showSpeedDialog(context);
                          },
                        ),
                        // const SizedBox(height: 16),
                        // // Subtitle/CC
                        // Row(
                        //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        //   children: [
                        //     const Text(
                        //       "Subtitle/CC",
                        //       style: TextStyle(color: Colors.white),
                        //     ),
                        //     Obx(
                        //       () => Switch(
                        //         value: controller.isSubtitleEnabled.value,
                        //         onChanged: (value) {
                        //           controller.toggleSubtitle(value);
                        //         },
                        //         activeColor: AppColors.red,
                        //         inactiveTrackColor: Colors.grey[700],
                        //       ),
                        //     ),
                        //   ],
                        // ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSettingRow({
    required String label,
    required Widget value,
    required VoidCallback onTap,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white)),
        TvFocusWrapper(
          onTap: () => onTap(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.grey[800]!),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                value,
                const SizedBox(width: 8),
                const Icon(
                  Icons.keyboard_arrow_down,
                  color: Colors.white,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // void _showQualityDialog(BuildContext context) {
  //   showGeneralDialog(
  //     context: context,
  //     barrierDismissible: true,
  //     barrierLabel: '',
  //     pageBuilder: (context, anim1, anim2) {
  //       return Center(
  //         child: Material(
  //           color: Colors.transparent,
  //           child: Container(
  //             width: MediaQuery.of(context).size.width * 0.7,
  //             constraints: BoxConstraints(
  //               maxHeight: MediaQuery.of(context).size.height * 0.6,
  //             ),
  //             decoration: BoxDecoration(
  //               color: AppColors.containerBgColor,
  //               borderRadius: BorderRadius.circular(12),
  //             ),
  //             child: Column(
  //               mainAxisSize: MainAxisSize.min,
  //               crossAxisAlignment: CrossAxisAlignment.start,
  //               children: [
  //                 const Padding(
  //                   padding: EdgeInsets.all(16.0),
  //                   child: Text(
  //                     "Quality",
  //                     style: TextStyle(
  //                       color: Colors.white,
  //                       fontSize: 18,
  //                       fontWeight: FontWeight.bold,
  //                     ),
  //                   ),
  //                 ),
  //                 Flexible(
  //                   child: Obx(() {
  //                     final tracks = controller.availableVideoTracks;
  //                     return ListView.builder(
  //                       shrinkWrap: true,
  //                       itemCount: tracks.length,
  //                       itemBuilder: (context, index) {
  //                         final track = tracks[index];
  //                         final isSelected =
  //                             controller.currentVideoTrack.value == track;

  //                         return InkWell(
  //                           onTap: () {
  //                             controller.setVideoTrack(track);
  //                             Navigator.pop(context);
  //                           },
  //                           child: Padding(
  //                             padding: const EdgeInsets.symmetric(
  //                               horizontal: 16,
  //                               vertical: 12,
  //                             ),
  //                             child: Row(
  //                               mainAxisAlignment:
  //                                   MainAxisAlignment.spaceBetween,
  //                               children: [
  //                                 Text(
  //                                   track == VideoTrack.auto()
  //                                       ? "Auto"
  //                                       : track.displayName,
  //                                   style: const TextStyle(color: Colors.white),
  //                                 ),
  //                                 Container(
  //                                   width: 18,
  //                                   height: 18,
  //                                   decoration: BoxDecoration(
  //                                     shape: BoxShape.circle,
  //                                     border: Border.all(
  //                                       color: isSelected
  //                                           ? AppColors.red
  //                                           : Colors.grey,
  //                                     ),
  //                                   ),
  //                                   child: isSelected
  //                                       ? Center(
  //                                           child: Container(
  //                                             width: 10,
  //                                             height: 10,
  //                                             decoration: const BoxDecoration(
  //                                               color: AppColors.red,
  //                                               shape: BoxShape.circle,
  //                                             ),
  //                                           ),
  //                                         )
  //                                       : null,
  //                                 ),
  //                               ],
  //                             ),
  //                           ),
  //                         );
  //                       },
  //                     );
  //                   }),
  //                 ),
  //               ],
  //             ),
  //           ),
  //         ),
  //       );
  //     },
  //   );
  // }

  void _showSpeedDialog(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      pageBuilder: (context, anim1, anim2) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.6,
              decoration: BoxDecoration(
                color: AppColors.containerBgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      "Playback Speed",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ListView.builder(
                    shrinkWrap: true,
                    itemCount: controller.availableSpeeds.length,
                    itemBuilder: (context, index) {
                      final speed = controller.availableSpeeds[index];
                      final isSelected =
                          controller.playbackSpeed.value == speed;

                      return TvFocusWrapper(
                        onTap: () {
                          controller.setPlaybackSpeed(speed);
                          Navigator.pop(context);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                speed == 1.0 ? "1" : speed.toString(),
                                style: const TextStyle(color: Colors.white),
                              ),
                              Container(
                                width: 18,
                                height: 18,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.red
                                        : Colors.grey,
                                  ),
                                ),
                                child: isSelected
                                    ? Center(
                                        child: Container(
                                          width: 10,
                                          height: 10,
                                          decoration: const BoxDecoration(
                                            color: AppColors.red,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      )
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

extension VideoTrackExtension on VideoTrack {
  String get displayName {
    if (this == VideoTrack.auto()) return "Auto";
    if (this == VideoTrack.no()) return "None";

    // If title is non-empty and seems useful, use it
    if (title == null || title!.isEmpty) return "video";
    // if (title!.isNotEmpty && title != "video") return title!;

    // Otherwise fallback to id or something descriptive
    return id.split('/').last.split('.').first;
  }
}

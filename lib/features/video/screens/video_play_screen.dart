import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_almightyflippa/core/constants/app_colors.dart';
import 'package:get/get.dart';

import '../controllers/video_play_controller.dart';

class VideoPlayScreen extends StatefulWidget {
  final int streamId;
  const VideoPlayScreen({super.key, required this.streamId});

  @override
  State<VideoPlayScreen> createState() => _VideoPlayScreenState();
}

class _VideoPlayScreenState extends State<VideoPlayScreen> {
  final controller = Get.put(VideoPlayController());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.getMovieDetails(streamId: widget.streamId);
    });
    }

  @override
  void dispose() {
    // Controller is disposed by GetX when screen is closed if we used Get.put
    // But since we want to be sure it cleans up, the controller's onClose handles it.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlack,
      body: SafeArea(
        child: Obx(() {
          if (controller.movieCtrl.isLoading.value) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.red),
            );
          }

          final movie = controller.movieCtrl.movie.value;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Video Player Header
              Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Container(
                      color: Colors.black,
                      child:
                          controller.isVideoInitialized.value &&
                              controller.chewieController != null
                          ? Chewie(controller: controller.chewieController!)
                          : const Center(
                              child: CircularProgressIndicator(
                                color: AppColors.red,
                              ),
                            ),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Get.back(),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: IconButton(
                      icon: const Icon(Icons.settings, color: Colors.white),
                      onPressed: () {
                        // TODO: Settings
                      },
                    ),
                  ),
                ],
              ),

              // Title and Info
              if (movie != null) ...[
                // Progress Bar (Video Player handles this usually, but mockup had one)
                // Chewie has built-in controls.
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          movie.streamData.info.name,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${movie.streamData.movieData.added} | Movie | ${movie.streamData.info.duration}',
                          style: const TextStyle(
                            color: AppColors.primaryGray,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          movie.streamData.info.description.isNotEmpty
                              ? movie.streamData.info.description
                              : (movie.streamData.info.plot.isNotEmpty
                                    ? movie.streamData.info.plot
                                    : 'No description available'),
                          style: const TextStyle(
                            color: AppColors.primaryGray,
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: () {
                            // Toggle expand description if needed
                          },
                          child: const Text(
                            'See More',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        const SizedBox(height: 30),
                        Center(
                          child: Column(
                            children: [
                              IconButton(
                                onPressed: () {},
                                icon: const Icon(
                                  Icons.favorite_border,
                                  color: Colors.white,
                                ),
                                iconSize: 30,
                              ),
                              const Text(
                                "Favourite",
                                style: TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          );
        }),
      ),
    );
  }
}

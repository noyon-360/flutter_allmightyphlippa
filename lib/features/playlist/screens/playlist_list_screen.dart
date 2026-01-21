import 'package:flutter/material.dart';
import 'package:flutter_almightyflippa/core/common/widgets/app_scaffold.dart';
import 'package:flutter_almightyflippa/core/common/widgets/button_widgets.dart';
import 'package:flutter_almightyflippa/core/constants/app_colors.dart';
import 'package:flutx_core/flutx_core.dart';
import 'package:get/get.dart';
import '../controllers/playlist_controller.dart';
import 'add_playlist_screen.dart';

class PlaylistListScreen extends StatelessWidget {
  const PlaylistListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final playlistCtrl = Get.put(PlaylistController());

    return AppScaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Gap(h: 40),
            Text(
              "Your Playlists",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.primaryWhite,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Gap(h: 20),
            Expanded(
              child: Obx(() {
                if (playlistCtrl.isFetchingList.value &&
                    playlistCtrl.playlists.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (playlistCtrl.playlists.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.playlist_add,
                          size: 80,
                          color: AppColors.primaryGray,
                        ),
                        const Gap(h: 16),
                        Text(
                          "No playlists found",
                          style: TextStyle(
                            color: AppColors.primaryGray,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => playlistCtrl.fetchPlaylists(),
                  child: ListView.separated(
                    itemCount: playlistCtrl.playlists.length,
                    separatorBuilder: (context, index) => const Gap(h: 12),
                    itemBuilder: (context, index) {
                      final playlist = playlistCtrl.playlists[index];
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlack.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.primaryWhite.withOpacity(0.1),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    playlist.name ?? "Unnamed",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const Gap(h: 4),
                                  Text(
                                    playlist.url ?? "No URL",
                                    style: TextStyle(
                                      color: AppColors.primaryGray,
                                      fontSize: 14,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const Gap(w: 12),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                              ),
                              onPressed: () => _showDeleteDialog(
                                context,
                                playlistCtrl
                              ),
                            ),
                            SecondaryButton(
                              text: "Select",
                              width: 80,
                              height: 40,
                              onSimplePressed: () =>
                                  playlistCtrl.selectPlaylist(playlist),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              }),
            ),
            const Gap(h: 20),
            PrimaryButton(
              text: "Add New Playlist",
              onSimplePressed: () => Get.to(() => const AddPlaylistScreen()),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(
    BuildContext context,
    PlaylistController controller,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.primaryBlack,
        title: const Text(
          "Delete Playlist",
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          "Are you sure you want to delete this playlist?",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(child: const Text("Cancel"), onPressed: () => Get.back()),
          TextButton(
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
            onPressed: () {
              Get.back();
            },
          ),
        ],
      ),
    );
  }
}

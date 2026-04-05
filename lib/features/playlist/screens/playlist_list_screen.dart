import 'package:flutter/material.dart';
import '/core/common/widgets/app_scaffold.dart';
import '/core/common/widgets/button_widgets.dart';
import '/core/constants/app_colors.dart';
import '/features/profile/controller/profile_controller.dart';
import 'package:flutx_core/flutx_core.dart';
import 'package:get/get.dart';
import '../controllers/playlist_controller.dart';
import 'add_playlist_screen.dart';

class PlaylistListScreen extends StatelessWidget {
  final bool isEdit;
  const PlaylistListScreen({super.key, this.isEdit = false});

  @override
  Widget build(BuildContext context) {
    final playlistCtrl = Get.put(PlaylistController());

    return AppScaffold(
      appBar: AppBar(
        title: const Text("Playlists"),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.person),
            color: AppColors.primaryBlack,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onSelected: (value) {
              if (value == 'logout') {
                Get.put(ProfileController()).logout();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.white, size: 20),
                    Gap(w: 12),
                    Text("Logout", style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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

              return RefreshIndicator.adaptive(
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
                              playlistCtrl,
                              playlist.id!,
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
            onSimplePressed: () {
              if (isEdit) {
                Get.to(() => AddPlaylistScreen(isEdit: true));
              } else {
                Get.to(() => AddPlaylistScreen(isEdit: false));
              }
            },
          ),
          Gap.bottomBarGap,
        ],
      ),
    );
  }

  void _showDeleteDialog(
    BuildContext context,
    PlaylistController controller,
    String id,
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
              controller.deletePlaylist(id);
            },
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '/core/common/widgets/app_scaffold.dart';
import '/core/common/widgets/button_widgets.dart';
import '/core/constants/app_colors.dart';
import '/features/profile/controller/profile_controller.dart';
import 'package:flutx_core/flutx_core.dart';
import 'package:get/get.dart';
import '../controllers/playlist_controller.dart';
import '../models/playlist_account_info.dart';
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
                    final isActive = playlistCtrl.isActivePlaylist(playlist);
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppColors.red.withOpacity(0.08)
                            : AppColors.primaryBlack.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isActive
                              ? AppColors.red.withOpacity(0.6)
                              : AppColors.primaryWhite.withOpacity(0.1),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        playlist.name ?? "Unnamed",
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (isActive) ...[
                                      const Gap(w: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.red,
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.check,
                                              color: Colors.white,
                                              size: 12,
                                            ),
                                            SizedBox(width: 2),
                                            Text(
                                              "Active",
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
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
                                const Gap(h: 6),
                                // Never a guess about the line's state: the
                                // cached badge while it is being refreshed, a
                                // placeholder while there is nothing yet, and
                                // an honest "unavailable" if the provider
                                // couldn't be reached.
                                if (playlist.accountInfo != null)
                                  _ExpiryBadge(info: playlist.accountInfo!)
                                else if (playlistCtrl.isFetchingList.value)
                                  const _ExpiryBadgePlaceholder()
                                else
                                  const _ExpiryBadgeUnavailable(),
                              ],
                            ),
                          ),
                          const Gap(w: 12),
                          PopupMenuButton<String>(
                            icon: const Icon(
                              Icons.more_vert,
                              color: Colors.white,
                            ),
                            color: AppColors.containerBgColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            onSelected: (value) {
                              switch (value) {
                                case 'update':
                                  playlistCtrl.updateControllers();
                                case 'edit':
                                  Get.to(
                                    () => AddPlaylistScreen(editing: playlist),
                                  );
                                case 'delete':
                                  _showDeleteDialog(
                                    context,
                                    playlistCtrl,
                                    playlist.id!,
                                  );
                              }
                            },
                            itemBuilder: (context) => [
                              // Only the playlist in use has content loaded to
                              // refresh; "Select" already reloads any other.
                              if (isActive)
                                _menuItem(
                                  'update',
                                  Icons.refresh,
                                  'Update Playlist',
                                ),
                              _menuItem('edit', Icons.edit_outlined, 'Edit'),
                              _menuItem(
                                'delete',
                                Icons.delete_outline,
                                'Delete',
                                color: Colors.red,
                              ),
                            ],
                          ),
                          SecondaryButton(
                            text: isActive ? "Selected" : "Select",
                            width: 90,
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

  PopupMenuItem<String> _menuItem(
    String value,
    IconData icon,
    String label, {
    Color color = Colors.white,
  }) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const Gap(w: 12),
          Text(label, style: TextStyle(color: color)),
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

/// Stands in for the badge while the first check of a line is still in
/// flight, pulsing so the row reads as loading rather than as a card that
/// simply has nothing to say.
class _ExpiryBadgePlaceholder extends StatefulWidget {
  const _ExpiryBadgePlaceholder();

  @override
  State<_ExpiryBadgePlaceholder> createState() =>
      _ExpiryBadgePlaceholderState();
}

class _ExpiryBadgePlaceholderState extends State<_ExpiryBadgePlaceholder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  late final Animation<double> _opacity = Tween<double>(
    begin: 0.35,
    end: 0.85,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tint = AppColors.primaryGray;

    return FadeTransition(
      opacity: _opacity,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: tint, shape: BoxShape.circle),
          ),
          const Gap(w: 6),
          Container(
            width: 120,
            height: 10,
            decoration: BoxDecoration(
              color: tint.withOpacity(0.35),
              borderRadius: BorderRadius.circular(5),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shown once the check has finished without an answer — the provider was
/// unreachable — so the gap in the card is explained instead of looking like
/// a badge that never loaded.
class _ExpiryBadgeUnavailable extends StatelessWidget {
  const _ExpiryBadgeUnavailable();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.primaryGray, width: 1.5),
          ),
        ),
        const Gap(w: 6),
        Text(
          'Status unavailable',
          style: TextStyle(
            color: AppColors.primaryGray.withOpacity(0.8),
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

/// The line's subscription state on a playlist card: a coloured dot plus
/// wording that says when it lapses, so an expired playlist reads as expired
/// rather than as a stream that mysteriously won't start.
class _ExpiryBadge extends StatelessWidget {
  final PlaylistAccountInfo info;

  const _ExpiryBadge({required this.info});

  @override
  Widget build(BuildContext context) {
    final color = info.indicatorColor;
    final needsAttention = info.isExpired || info.isExpiringSoon;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const Gap(w: 6),
        Flexible(
          child: Text(
            info.label,
            style: TextStyle(
              color: needsAttention ? color : AppColors.primaryGray,
              fontSize: 13,
              fontWeight: needsAttention ? FontWeight.w600 : FontWeight.w400,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

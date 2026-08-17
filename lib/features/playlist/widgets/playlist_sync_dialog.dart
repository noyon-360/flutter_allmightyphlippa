import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../controllers/playlist_controller.dart';

/// Blocking status dialog shown while a playlist's initial movies/series/live
/// TV data is being fetched after add/select, so the user can tell whether
/// setup is still updating, has completed, or failed — instead of being
/// dropped onto a silently-loading Home screen with no feedback.
class PlaylistSyncDialog extends StatelessWidget {
  const PlaylistSyncDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final playlistCtrl = Get.find<PlaylistController>();

    return PopScope(
      canPop: false,
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.75,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            decoration: BoxDecoration(
              color: AppColors.containerBgColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Obx(() {
              switch (playlistCtrl.syncStatus.value) {
                case PlaylistSyncStatus.completed:
                  return const _SyncStatusContent(
                    icon: Icons.check_circle,
                    iconColor: AppColors.successGreen,
                    title: "Completed",
                    subtitle: "Your playlist is ready.",
                  );
                case PlaylistSyncStatus.failed:
                  return const _SyncStatusContent(
                    icon: Icons.error_outline,
                    iconColor: AppColors.red,
                    title: "Failed",
                    subtitle:
                        "Some content couldn't be loaded. You can try again from the playlist settings.",
                  );
                case PlaylistSyncStatus.updating:
                case PlaylistSyncStatus.idle:
                  return const _SyncStatusContent(
                    title: "Updating",
                    subtitle: "Setting up your playlist…",
                    showSpinner: true,
                  );
              }
            }),
          ),
        ),
      ),
    );
  }
}

class _SyncStatusContent extends StatelessWidget {
  final IconData? icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool showSpinner;

  const _SyncStatusContent({
    this.icon,
    this.iconColor = AppColors.red,
    required this.title,
    required this.subtitle,
    this.showSpinner = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showSpinner)
          const SizedBox(
            width: 36,
            height: 36,
            child: CircularProgressIndicator(
              color: AppColors.red,
              strokeWidth: 3,
            ),
          )
        else
          Icon(icon, color: iconColor, size: 40),
        const SizedBox(height: 16),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.primaryGray, fontSize: 13),
        ),
      ],
    );
  }
}

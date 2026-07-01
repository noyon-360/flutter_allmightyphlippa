import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/download_controller.dart';

class DownloadButton extends StatelessWidget {
  final String videoId;
  final String videoType; // 'movie' or 'series'
  final String title;
  final String url;
  final String ext;
  final String? thumbnail;
  final double iconSize;

  const DownloadButton({
    super.key,
    required this.videoId,
    required this.videoType,
    required this.title,
    required this.url,
    required this.ext,
    this.thumbnail,
    this.iconSize = 22,
  });

  @override
  Widget build(BuildContext context) {
    final ctrl = DownloadController.to;
    return Obx(() {
      final downloaded = ctrl.isDownloaded(videoId, videoType);
      final downloading = ctrl.isDownloading(videoId, videoType);
      final progress = ctrl.progressOf(videoId, videoType);

      if (downloaded) {
        return IconButton(
          icon: Icon(
            Icons.download_done,
            color: Colors.greenAccent,
            size: iconSize,
          ),
          tooltip: 'Downloaded — tap to delete',
          onPressed: () => _confirmDelete(context, ctrl),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        );
      }

      if (downloading) {
        return SizedBox(
          width: iconSize + 4,
          height: iconSize + 4,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: CircularProgressIndicator(
                  value: progress > 0 ? progress : null,
                  strokeWidth: 2,
                  color: Colors.white70,
                ),
              ),
              GestureDetector(
                onTap: () => ctrl.cancel(videoId, videoType),
                child: Icon(
                  Icons.close,
                  size: iconSize - 8,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        );
      }

      return IconButton(
        icon: Icon(
          Icons.download_outlined,
          // color: Colors.white70,
          size: iconSize,
        ),
        tooltip: 'Download for offline',
        onPressed: () => ctrl.download(
          videoId: videoId,
          videoType: videoType,
          title: title,
          url: url,
          ext: ext,
          thumbnail: thumbnail,
        ),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
      );
    });
  }

  void _confirmDelete(BuildContext context, DownloadController ctrl) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'Delete Download',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Remove "$title" from your downloads?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              ctrl.delete(videoId, videoType);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

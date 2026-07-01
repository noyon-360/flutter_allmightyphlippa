import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_almightyflippa/features/playlist/models/server_request_model.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_colors.dart';
import '../../video/screens/video_play_screen.dart';
import '../controllers/download_controller.dart';
import '../models/download_item.dart';
import '../services/download_service.dart';

class DownloadsScreen extends StatelessWidget {
  const DownloadsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = DownloadController.to;
    final svc = DownloadService.to;

    return Scaffold(
      backgroundColor: AppColors.primaryBlack,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlack,
        title: const Text('Downloads', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Obx(() {
        final all = ctrl.items;
        if (all.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.download_for_offline_outlined, size: 72, color: Colors.white24),
                SizedBox(height: 16),
                Text(
                  'No downloads yet',
                  style: TextStyle(color: Colors.white54, fontSize: 16),
                ),
                SizedBox(height: 8),
                Text(
                  'Download movies or episodes to watch offline',
                  style: TextStyle(color: Colors.white38, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          itemCount: all.length,
          separatorBuilder: (ctx, i) => const SizedBox(height: 10),
          itemBuilder: (ctx, i) => _DownloadTile(item: all[i], svc: svc, ctrl: ctrl),
        );
      }),
    );
  }
}

class _DownloadTile extends StatelessWidget {
  final DownloadItem item;
  final DownloadService svc;
  final DownloadController ctrl;

  const _DownloadTile({required this.item, required this.svc, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: _thumbnail(),
        title: Text(
          item.title,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: _subtitle(),
        trailing: _trailing(context),
        onTap: item.isCompleted ? () => _play() : null,
      ),
    );
  }

  Widget _thumbnail() {
    if (item.thumbnail != null && item.thumbnail!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.network(
          item.thumbnail!,
          width: 64,
          height: 48,
          fit: BoxFit.cover,
          errorBuilder: (ctx, err, st) => _iconBox(),
        ),
      );
    }
    return _iconBox();
  }

  Widget _iconBox() => Container(
    width: 64,
    height: 48,
    decoration: BoxDecoration(
      color: Colors.white10,
      borderRadius: BorderRadius.circular(6),
    ),
    child: const Icon(Icons.movie_outlined, color: Colors.white30),
  );

  Widget _subtitle() {
    switch (item.status) {
      case DownloadStatus.completed:
        final size = svc.formatFileSize(item.fileSize);
        return Text(
          '${item.videoType.capitalize} • ${size.isNotEmpty ? size : 'Ready'}',
          style: const TextStyle(color: Colors.greenAccent, fontSize: 12),
        );
      case DownloadStatus.downloading:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: item.progress > 0 ? item.progress : null,
              backgroundColor: Colors.white12,
              color: AppColors.red,
              minHeight: 3,
              borderRadius: BorderRadius.circular(2),
            ),
            const SizedBox(height: 4),
            Text(
              '${(item.progress * 100).toStringAsFixed(0)}% • ${svc.formatFileSize(item.fileSize)}',
              style: const TextStyle(color: Colors.white54, fontSize: 11),
            ),
          ],
        );
      case DownloadStatus.failed:
        return const Text('Failed — tap retry', style: TextStyle(color: Colors.redAccent, fontSize: 12));
      case DownloadStatus.queued:
        return const Text('Queued…', style: TextStyle(color: Colors.white38, fontSize: 12));
    }
  }

  Widget _trailing(BuildContext context) {
    switch (item.status) {
      case DownloadStatus.completed:
        return IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.white38),
          onPressed: () => _confirmDelete(context),
        );
      case DownloadStatus.downloading:
        return IconButton(
          icon: const Icon(Icons.close, color: Colors.white38),
          onPressed: () => ctrl.cancel(item.videoId, item.videoType),
        );
      case DownloadStatus.failed:
        return IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white38),
          onPressed: () => ctrl.download(
            videoId: item.videoId,
            videoType: item.videoType,
            title: item.title,
            url: item.url,
            ext: item.ext,
            thumbnail: item.thumbnail,
          ),
        );
      case DownloadStatus.queued:
        return const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white38),
        );
    }
  }

  void _play() {
    final localFile = File(item.localPath);
    if (!localFile.existsSync()) {
      Get.snackbar('File Missing', 'The downloaded file was not found. Please re-download.');
      return;
    }
    final type = item.videoType == 'movie' ? ServerType.movies : ServerType.series;
    Get.to(() => VideoPlayScreen(
      streamId: int.tryParse(item.videoId) ?? 0,
      type: type,
      localPath: item.localPath,
    ));
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Delete Download', style: TextStyle(color: Colors.white)),
        content: Text(
          'Remove "${item.title}" from downloads?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
          TextButton(
            onPressed: () { Get.back(); ctrl.delete(item.videoId, item.videoType); },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

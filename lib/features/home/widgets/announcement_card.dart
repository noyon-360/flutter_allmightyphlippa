import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../models/announcement_model.dart';

/// The announcement banner at the top of Home: an icon and colour per type,
/// title, message, an optional action button, and a close button.
class AnnouncementCard extends StatelessWidget {
  final AnnouncementModel announcement;
  final VoidCallback onDismiss;

  const AnnouncementCard({
    super.key,
    required this.announcement,
    required this.onDismiss,
  });

  ({Color color, IconData icon}) get _style => switch (announcement.type) {
    AnnouncementType.update => (
      color: AppColors.red,
      icon: Icons.system_update_alt,
    ),
    AnnouncementType.feature => (
      color: const Color(0xFF4C8DFF),
      icon: Icons.auto_awesome,
    ),
    AnnouncementType.maintenance => (
      color: const Color(0xFFFFB300),
      icon: Icons.build_circle_outlined,
    ),
    AnnouncementType.important => (
      color: const Color(0xFFFF6E40),
      icon: Icons.campaign_outlined,
    ),
    AnnouncementType.info => (
      color: const Color(0xFF90A4AE),
      icon: Icons.info_outline,
    ),
  };

  Future<void> _openAction() async {
    final uri = Uri.tryParse(announcement.actionUrl ?? '');
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final style = _style;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
      decoration: BoxDecoration(
        color: style.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: style.color.withValues(alpha: 0.45)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: style.color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(style.icon, color: style.color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    announcement.title,
                    style: const TextStyle(
                      color: AppColors.primaryWhite,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    announcement.message,
                    style: TextStyle(
                      color: AppColors.primaryWhite.withValues(alpha: 0.8),
                      fontSize: 14,
                      height: 1.35,
                    ),
                  ),
                  if (announcement.hasAction) ...[
                    const SizedBox(height: 6),
                    TextButton(
                      onPressed: _openAction,
                      style: TextButton.styleFrom(
                        foregroundColor: style.color,
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 32),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        announcement.actionLabel!,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          IconButton(
            tooltip: 'Dismiss',
            visualDensity: VisualDensity.compact,
            onPressed: onDismiss,
            icon: Icon(
              Icons.close,
              size: 18,
              color: AppColors.primaryWhite.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

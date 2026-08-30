import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/common/widgets/tv_focus_wrapper.dart';
import '../../../core/constants/app_colors.dart';
import '../controllers/epg_controller.dart';
import '../models/epg_program_model.dart';

/// Bottom sheet showing a program's title, time range, and description
/// (when available), plus a reminder toggle for programs that haven't
/// started yet. Shared between the EPG timeline grid and the live player's
/// program strip so both present the same info in the same way.
void showEpgProgramInfoSheet(
  BuildContext context, {
  required EpgProgramModel program,
  required int streamId,
  required String channelName,
  required bool isFuture,
}) {
  final channelId = streamId.toString();
  final epgCtrl = EpgController.to;

  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.containerBgColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            program.title,
            style: const TextStyle(
              color: AppColors.primaryWhite,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                program.timeRange,
                style: const TextStyle(
                  color: AppColors.red,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (isFuture) ...[
                const Spacer(),
                Obx(() {
                  final hasReminder = epgCtrl.hasReminder(program, channelId);
                  return TvFocusWrapper(
                    onTap: hasReminder
                        ? null
                        : () => epgCtrl.setReminder(
                            channelId: channelId,
                            channelName: channelName,
                            program: program,
                          ),
                    child: Icon(
                      hasReminder
                          ? Icons.notifications_active
                          : Icons.notifications_none,
                      color: hasReminder
                          ? AppColors.red
                          : AppColors.primaryGray,
                      size: 22,
                    ),
                  );
                }),
              ],
            ],
          ),
          if (program.description.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              program.description,
              style: const TextStyle(
                color: AppColors.primaryGray,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

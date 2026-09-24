import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../controllers/playlist_controller.dart';
import '../models/playlist_sync_step.dart';

/// Blocking status dialog shown while a playlist's content is loaded or
/// refreshed, so the user can always tell whether it's working, stuck,
/// finished, or failed: a headline for the step in progress plus a checklist
/// of every step. After a failure it offers to retry the failed steps or
/// carry on with what loaded.
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
            width: MediaQuery.of(context).size.width * 0.85,
            constraints: const BoxConstraints(maxWidth: 420),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            decoration: BoxDecoration(
              color: AppColors.containerBgColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Obx(() {
              final status = playlistCtrl.syncStatus.value;
              final steps = playlistCtrl.syncSteps;
              final failed = status == PlaylistSyncStatus.failed;
              final completed = status == PlaylistSyncStatus.completed;

              // Read every step's state so this Obx rebuilds as each changes.
              final running = steps.firstWhereOrNull(
                (s) => s.state.value == SyncStepState.running,
              );
              final doneCount = steps
                  .where((s) => s.state.value == SyncStepState.done)
                  .length;

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (completed)
                    const Icon(
                      Icons.check_circle,
                      color: AppColors.successGreen,
                      size: 40,
                    )
                  else if (failed)
                    const Icon(
                      Icons.error_outline,
                      color: AppColors.red,
                      size: 40,
                    )
                  else
                    const SizedBox(
                      width: 36,
                      height: 36,
                      child: CircularProgressIndicator(
                        color: AppColors.red,
                        strokeWidth: 3,
                      ),
                    ),
                  const SizedBox(height: 16),
                  Text(
                    completed
                        ? 'Complete'
                        : failed
                        ? 'Some content couldn\'t be loaded'
                        : (running?.activeText ?? 'Connecting to Server…'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    steps.isEmpty ? '' : '$doneCount of ${steps.length} done',
                    style: const TextStyle(
                      color: AppColors.primaryGray,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 16),
                  for (final step in steps) _StepRow(step: step),
                  if (failed) ...[
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: playlistCtrl.continueAfterFailedSync,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white54),
                            ),
                            child: const Text('Continue'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: playlistCtrl.retrySync,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.red,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Retry'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  final SyncStep step;

  const _StepRow({required this.step});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final state = step.state.value;
      final Widget icon = switch (state) {
        SyncStepState.done => const Icon(
          Icons.check_circle,
          color: AppColors.successGreen,
          size: 16,
        ),
        SyncStepState.failed => const Icon(
          Icons.cancel,
          color: AppColors.red,
          size: 16,
        ),
        SyncStepState.running => const SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(
            color: AppColors.red,
            strokeWidth: 2,
          ),
        ),
        SyncStepState.pending => const Icon(
          Icons.radio_button_unchecked,
          color: AppColors.primaryGray,
          size: 16,
        ),
      };

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            SizedBox(width: 20, child: Center(child: icon)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                step.label,
                style: TextStyle(
                  color: state == SyncStepState.pending
                      ? AppColors.primaryGray
                      : Colors.white,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}

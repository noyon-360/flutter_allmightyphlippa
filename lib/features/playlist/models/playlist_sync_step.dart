import 'package:get/get.dart';

enum SyncStepState { pending, running, done, failed }

/// One unit of work in a playlist update, shown as a row in the sync dialog.
class SyncStep {
  /// Short name shown in the checklist ("Live TV channels").
  final String label;

  /// Shown as the headline while this step is the one running
  /// ("Getting Live TV Channels…").
  final String activeText;

  final Rx<SyncStepState> state = SyncStepState.pending.obs;

  SyncStep({required this.label, required this.activeText});
}

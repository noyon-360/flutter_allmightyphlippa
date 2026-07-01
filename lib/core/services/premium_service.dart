import 'package:get/get.dart';

import '../../features/profile/controller/profile_controller.dart';
import 'revenuecat_service.dart';

/// Single source of truth for premium status.
///
/// Checks two independent sources and considers the user premium if EITHER
/// confirms it:
///   - RevenueCat entitlement (real-time, client-side)
///   - Backend user profile  (server-authoritative)
///
/// Usage:
///   // Reactive (inside Obx):
///   PremiumService.to.isPremium.value
///
///   // One-shot check:
///   PremiumService.to.check
///
///   // After a profile refresh:
///   PremiumService.to.refresh()
class PremiumService extends GetxService {
  static PremiumService get to => Get.find<PremiumService>();

  late final RevenueCatService _rc;

  /// Reactive premium flag. Observe with Obx or .value in GetX workers.
  final isPremium = false.obs;

  @override
  void onInit() {
    super.onInit();
    _rc = Get.find<RevenueCatService>();
    ever(_rc.customerInfo, (_) => _evaluate());
    _evaluate();
  }

  /// Synchronous check — use in non-reactive code.
  bool get check => isPremium.value;

  /// Call this after the user profile has been fetched / refreshed.
  void refresh() => _evaluate();

  void _evaluate() {
    isPremium.value = _fromRevenueCat() || _fromBackend();
  }

  bool _fromRevenueCat() => _rc.hasActiveSubscription;

  bool _fromBackend() {
    if (!Get.isRegistered<ProfileController>()) return false;
    final user = Get.find<ProfileController>().userProfile.value;
    if (user == null) return false;

    // Backend only sets plan="premium" when status is active/trialing,
    // so this is the single most reliable field.
    final isPremiumPlan = user.plan == 'premium';

    // Guard against stale data: backend has no auto-downgrade on expiry,
    // so check the expiry date locally if it's present.
    final notExpired =
        user.subscriptionExpiresAt == null ||
        user.subscriptionExpiresAt!.isAfter(DateTime.now());

    return isPremiumPlan && notExpired;
  }
}

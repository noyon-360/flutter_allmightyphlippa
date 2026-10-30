import 'dart:async';

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

    // Mirrors the backend's isPremium middleware: premium plan, active status
    // and an expiry date that hasn't passed yet (the backend only downgrades
    // expired users once a day, so the plan field alone can be stale).
    final isPremium = user.plan == 'premium' && user.hasActiveSubscription;

    _scheduleExpiryCheck(isPremium ? user.subscriptionExpiresAt : null);
    return isPremium;
  }

  Timer? _expiryTimer;

  /// Re-evaluates the moment the backend's expiry date passes, so premium
  /// features switch off while the app stays open.
  void _scheduleExpiryCheck(DateTime? expiresAt) {
    _expiryTimer?.cancel();
    if (expiresAt == null) return;
    final delay = expiresAt.difference(DateTime.now());
    if (delay.isNegative) return;
    _expiryTimer = Timer(delay + const Duration(seconds: 1), _evaluate);
  }

  @override
  void onClose() {
    _expiryTimer?.cancel();
    super.onClose();
  }
}

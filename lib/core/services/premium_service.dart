import 'dart:async';

import 'package:get/get.dart';

import '../../features/auth/models/user_response_model.dart';
import '../../features/profile/controller/profile_controller.dart';
import 'pip_service.dart';
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
  /// True during a free trial too.
  final isPremium = false.obs;

  /// Premium, but still in the store's free trial.
  final isFreeTrial = false.obs;

  /// Premium on a paid period. Some features (parental lock) are for paying
  /// subscribers only and stay closed during the free trial.
  bool get hasPaidPremium => isPremium.value && !isFreeTrial.value;

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
    final fromStore = _fromRevenueCat();
    isPremium.value = fromStore || _fromBackend();
    // This device's store entitlement is the freshest answer (the backend
    // hears about the trial ending through a webhook); otherwise use the
    // backend, e.g. for a trial started on another device.
    isFreeTrial.value = isPremium.value &&
        (fromStore ? _rc.isInFreeTrial : _backendUser()?.isOnFreeTrial ?? false);
    // Losing premium mid-playback must not leave auto-PiP armed.
    if (!isPremium.value) PiPService.disarmAll();
  }

  UserModel? _backendUser() => Get.isRegistered<ProfileController>()
      ? Get.find<ProfileController>().userProfile.value
      : null;

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

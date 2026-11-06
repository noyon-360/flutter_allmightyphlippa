import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutx_core/flutx_core.dart';
import 'package:get/get.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../features/profile/controller/profile_controller.dart';
import '../../features/subscription/models/free_trial_offer.dart';
import 'auth_storage_service.dart';

/// Outcome of a purchase or restore attempt.
enum PurchaseOutcome { success, cancelled, notEntitled, error }

class RevenueCatService extends GetxService {
  // ── API Keys ────────────────────────────────────────────────────────────────
  // Set _androidApiKey to your Google Play key from the RevenueCat dashboard.
  static const String _iOSApiKey = 'appl_PMseeyUCLgpEOZlpbwibGKUAUMj';
  static const String _androidApiKey = 'goog_kQPsjVmDCiGsyMnnFlFoFpNCwtv';

  /// Entitlement identifier configured in the RevenueCat dashboard.
  static const String entitlementId = 'LABBY TV Pro';

  /// Product identifiers — must match App Store Connect / Google Play Console.
  static const String monthlyProductId = 'month_subscription';
  static const String quarterlyProductId = 'premium_quarterly';
  static const String yearlyProductId = 'premium_t_yearly';

  /// Google Play reports subscriptions as `productId:basePlanId`
  /// (e.g. "month_subscription:monthly-base-plan"); Apple uses the bare ID.
  /// Strip the base plan so both platforms match the constants above.
  static String baseProductId(String? id) => (id ?? '').split(':').first;

  // ── Dependencies ────────────────────────────────────────────────────────────
  late final AuthStorageService _authStorage;

  // ── Observable State ────────────────────────────────────────────────────────
  final customerInfo = Rxn<CustomerInfo>();
  final offerings = Rxn<Offerings>();
  final isLoading = false.obs;
  final isConfigured = false.obs;

  /// True while the initial offerings fetch is in progress.
  final isOfferingsLoading = true.obs;

  /// iOS free-trial eligibility per store product ID. Empty on Android, where
  /// Play only returns the trial offer to eligible users.
  final introEligibility = <String, IntroEligibilityStatus>{}.obs;

  // ── Computed Properties ─────────────────────────────────────────────────────
  bool get hasActiveSubscription =>
      customerInfo.value?.entitlements.active.containsKey(entitlementId) ??
      false;

  EntitlementInfo? get activeEntitlement =>
      customerInfo.value?.entitlements.active[entitlementId];

  /// Expiration date string in ISO 8601 format (e.g. "2025-06-29T00:00:00Z").
  String? get expirationDateString => activeEntitlement?.expirationDate;

  /// Parsed expiration date — null if no active entitlement or no expiry.
  DateTime? get expirationDate {
    final raw = expirationDateString;
    return raw != null ? DateTime.tryParse(raw) : null;
  }

  /// True while the store entitlement is in its free-trial period. The
  /// backend's "trialing" status can lag the webhook by a few seconds.
  bool get isInFreeTrial => activeEntitlement?.periodType == PeriodType.trial;

  /// The free trial this user can get on [package], or null.
  FreeTrialOffer? freeTrialFor(Package package) => FreeTrialOffer.fromProduct(
    package.storeProduct,
    isIOS: Platform.isIOS,
    iosEligibility: introEligibility[package.storeProduct.identifier],
  );

  /// A free trial this user can start on any plan, for "try it free" prompts.
  FreeTrialOffer? get availableFreeTrial {
    for (final p in availablePackages) {
      final trial = freeTrialFor(p);
      if (trial != null) return trial;
    }
    return null;
  }

  String? get activeProductIdentifier {
    final id = activeEntitlement?.productIdentifier;
    return id == null ? null : baseProductId(id);
  }

  List<Package> get availablePackages =>
      offerings.value?.current?.availablePackages ?? [];

  // ── Lifecycle ───────────────────────────────────────────────────────────────
  @override
  void onInit() {
    super.onInit();
    _authStorage = Get.find<AuthStorageService>();
    _configure();
  }

  Future<void> _configure() async {
    try {
      final apiKey = Platform.isIOS ? _iOSApiKey : _androidApiKey;
      await Purchases.configure(PurchasesConfiguration(apiKey));
      await Purchases.setLogLevel(LogLevel.debug);
      isConfigured.value = true;

      Purchases.addCustomerInfoUpdateListener(_onCustomerInfoUpdated);

      await _identifyUser();
      await Future.wait([refreshCustomerInfo(), fetchOfferings()]);
    } catch (e) {
      debugPrint('[RevenueCat] configure error: $e');
    }
  }

  Future<void> _identifyUser() async {
    try {
      final userId = await _authStorage.getUserId();
      if (userId != null && userId.isNotEmpty) {
        final result = await Purchases.logIn(userId);
        customerInfo.value = result.customerInfo;
      }
    } catch (e) {
      debugPrint('[RevenueCat] identifyUser error: $e');
    }
  }

  void _onCustomerInfoUpdated(CustomerInfo info) {
    customerInfo.value = info;
  }

  // ── Public API ──────────────────────────────────────────────────────────────

  Future<void> refreshCustomerInfo() async {
    try {
      customerInfo.value = await Purchases.getCustomerInfo();
    } catch (e) {
      debugPrint('[RevenueCat] refreshCustomerInfo error: $e');
    }
  }

  Future<void> fetchOfferings() async {
    isOfferingsLoading.value = true;
    try {
      offerings.value = await Purchases.getOfferings();
      await _checkIntroEligibility();
    } catch (e) {
      debugPrint('[RevenueCat] fetchOfferings error: $e');
    } finally {
      isOfferingsLoading.value = false;
    }
  }

  /// Apple shows every user the product's intro offer, even those who already
  /// used a trial, so ask StoreKit who is eligible before advertising it.
  Future<void> _checkIntroEligibility() async {
    if (!Platform.isIOS) return;
    final ids = availablePackages.map((p) => p.storeProduct.identifier).toList();
    if (ids.isEmpty) return;
    try {
      final result = await Purchases.checkTrialOrIntroductoryPriceEligibility(ids);
      introEligibility.assignAll(result.map((id, e) => MapEntry(id, e.status)));
    } catch (e) {
      debugPrint('[RevenueCat] intro eligibility error: $e');
    }
  }

  /// Purchase a [Package] from the current offering.
  Future<PurchaseOutcome> purchasePackage(Package package) async {
    if (isLoading.value) return PurchaseOutcome.error;
    isLoading.value = true;
    DPrint.log("Purchase package -> ${package.storeProduct.identifier}");
    try {
      final result = await Purchases.purchase(PurchaseParams.package(package))
          .timeout(
            const Duration(minutes: 5),
            onTimeout: () =>
                throw Exception('Purchase timed out. Please try again.'),
          );
      customerInfo.value = result.customerInfo;
      final entitled = result.customerInfo.entitlements.active.containsKey(
        entitlementId,
      );
      _refreshProfileAfterPurchase();
      return entitled ? PurchaseOutcome.success : PurchaseOutcome.notEntitled;
    } on PlatformException catch (e) {
      final code = PurchasesErrorHelper.getErrorCode(e);
      if (code == PurchasesErrorCode.purchaseCancelledError) {
        return PurchaseOutcome.cancelled;
      }
      debugPrint('[RevenueCat] purchase error: $code – ${e.message}');
      return PurchaseOutcome.error;
    } catch (e) {
      debugPrint('[RevenueCat] purchase unknown error: $e');
      return PurchaseOutcome.error;
    } finally {
      isLoading.value = false;
    }
  }

  /// Restore previous purchases for the current user.
  Future<PurchaseOutcome> restorePurchases() async {
    isLoading.value = true;
    try {
      final info = await Purchases.restorePurchases();
      customerInfo.value = info;
      final entitled = info.entitlements.active.containsKey(entitlementId);
      if (entitled) {
        _refreshProfileAfterPurchase();
      }
      return entitled ? PurchaseOutcome.success : PurchaseOutcome.notEntitled;
    } catch (e) {
      debugPrint('[RevenueCat] restorePurchases error: $e');
      return PurchaseOutcome.error;
    } finally {
      isLoading.value = false;
    }
  }

  /// Call when the user logs into your app to tie RevenueCat to your backend ID.
  Future<void> loginUser(String userId) async {
    try {
      final result = await Purchases.logIn(userId);
      customerInfo.value = result.customerInfo;
      await fetchOfferings();
    } catch (e) {
      debugPrint('[RevenueCat] loginUser error: $e');
    }
  }

  /// Call on logout so RevenueCat switches back to an anonymous user.
  Future<void> logoutUser() async {
    try {
      customerInfo.value = await Purchases.logOut();
    } catch (e) {
      debugPrint('[RevenueCat] logoutUser error: $e');
    }
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  /// Returns the [Package] for a given product identifier, or null if not found.
  /// Matches on the base product ID, so Android's `product:basePlan`
  /// identifiers resolve too.
  Package? getPackageByProductId(String productId) {
    final wanted = baseProductId(productId);
    try {
      return availablePackages.firstWhere(
        (p) => baseProductId(p.storeProduct.identifier) == wanted,
      );
    } catch (_) {
      return null;
    }
  }

  /// The backend learns about purchases from RevenueCat's webhook, which can
  /// land a few seconds after the store confirms. Refresh now and again
  /// shortly after so the profile (plan banner, history) catches up.
  void _refreshProfileAfterPurchase() {
    for (final delay in const [
      Duration.zero,
      Duration(seconds: 4),
      Duration(seconds: 12),
    ]) {
      Future.delayed(delay, () {
        if (Get.isRegistered<ProfileController>()) {
          Get.find<ProfileController>().refreshProfile();
        }
      });
    }
  }

  // ── Cleanup ─────────────────────────────────────────────────────────────────
  @override
  void onClose() {
    Purchases.removeCustomerInfoUpdateListener(_onCustomerInfoUpdated);
    super.onClose();
  }
}

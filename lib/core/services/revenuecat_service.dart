import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutx_core/flutx_core.dart';
import 'package:get/get.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../features/profile/controller/profile_controller.dart';
import '../../features/subscription/repositories/subscription_repo.dart';
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

  static const String _packageName = 'com.almightyflippa.labbytv';

  // ── Dependencies ────────────────────────────────────────────────────────────
  late final SubscriptionRepo _subscriptionRepo;
  late final AuthStorageService _authStorage;

  // ── Observable State ────────────────────────────────────────────────────────
  final customerInfo = Rxn<CustomerInfo>();
  final offerings = Rxn<Offerings>();
  final isLoading = false.obs;
  final isConfigured = false.obs;

  /// True while the initial offerings fetch is in progress.
  final isOfferingsLoading = true.obs;

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

  String? get activeProductIdentifier => activeEntitlement?.productIdentifier;

  List<Package> get availablePackages =>
      offerings.value?.current?.availablePackages ?? [];

  // ── Lifecycle ───────────────────────────────────────────────────────────────
  @override
  void onInit() {
    super.onInit();
    _subscriptionRepo = Get.find<SubscriptionRepo>();
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
    } catch (e) {
      debugPrint('[RevenueCat] fetchOfferings error: $e');
    } finally {
      isOfferingsLoading.value = false;
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
      // Always notify the backend — the payment happened on Apple/Google's side
      // regardless of whether RevenueCat's entitlement is configured correctly.
      await _verifyWithBackend(result.customerInfo, result.storeTransaction);
      _refreshProfile();
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
        _refreshProfile();
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

  // ── Backend Verification ────────────────────────────────────────────────────
  // RevenueCat validates receipts automatically on their servers. These calls
  // notify your backend so it can update the user record. For the most robust
  // integration, configure RevenueCat webhooks in the dashboard so the backend
  // is notified server-to-server without relying on the client.

  Future<void> _verifyWithBackend(
    CustomerInfo info,
    StoreTransaction transaction,
  ) async {
    try {
      if (Platform.isIOS) {
        // For a new iOS purchase, transactionIdentifier == originalTransactionId.
        final txId = transaction.transactionIdentifier.isNotEmpty
            ? transaction.transactionIdentifier
            : info.originalAppUserId;
        final result = await _subscriptionRepo.verifyApplePurchase(txId);
        result.fold(
          (f) => debugPrint('[RevenueCat] iOS verify failed: ${f.message}'),
          (_) => debugPrint('[RevenueCat] iOS verify success'),
        );
      } else if (Platform.isAndroid) {
        // The RevenueCat Flutter SDK does not expose the raw Google purchase
        // token. Use RevenueCat server-to-server webhooks or call RevenueCat's
        // REST API from your backend using the subscriber ID below.
        debugPrint(
          '[RevenueCat] Android subscriber: ${info.originalAppUserId} '
          'product: ${transaction.productIdentifier}',
        );
        final result = await _subscriptionRepo.verifyGooglePurchase(
          purchaseToken: transaction.transactionIdentifier,
          subscriptionId: transaction.productIdentifier,
          packageName: _packageName,
        );
        result.fold(
          (f) => debugPrint('[RevenueCat] Android verify failed: ${f.message}'),
          (_) => debugPrint('[RevenueCat] Android verify success'),
        );
      }
    } catch (e) {
      debugPrint('[RevenueCat] _verifyWithBackend error: $e');
    }
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  /// Returns the [Package] for a given product identifier, or null if not found.
  Package? getPackageByProductId(String productId) {
    try {
      return availablePackages.firstWhere(
        (p) => p.storeProduct.identifier == productId,
      );
    } catch (_) {
      return null;
    }
  }

  void _refreshProfile() {
    if (Get.isRegistered<ProfileController>()) {
      Get.find<ProfileController>().refreshProfile();
    }
  }

  // ── Cleanup ─────────────────────────────────────────────────────────────────
  @override
  void onClose() {
    Purchases.removeCustomerInfoUpdateListener(_onCustomerInfoUpdated);
    super.onClose();
  }
}

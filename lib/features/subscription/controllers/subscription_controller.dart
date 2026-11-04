import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutx_core/flutx_core.dart';
import 'package:get/get.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/services/revenuecat_service.dart';
import '../../../core/utils/tv_device.dart';
import '../../profile/controller/profile_controller.dart';
import '../models/subscription_history_model.dart';
import '../repositories/subscription_repo.dart';

class SubscriptionController extends GetxController {
  RevenueCatService get _service => Get.find<RevenueCatService>();
  final _subscriptionRepo = Get.find<SubscriptionRepo>();

  // Product ID constants matching App Store Connect / Google Play Console.
  static const String monthlyId = RevenueCatService.monthlyProductId;
  static const String quarterlyId = RevenueCatService.quarterlyProductId;
  static const String yearlyId = RevenueCatService.yearlyProductId;

  // ── Observable State ────────────────────────────────────────────────────────
  final isLoading = false.obs;
  final purchaseHistory = <SubscriptionHistoryModel>[].obs;
  final isHistoryLoading = false.obs;
  final selectedProductId = monthlyId.obs;

  // ── Forwarded from RevenueCatService ────────────────────────────────────────
  Rxn<CustomerInfo> get customerInfo => _service.customerInfo;
  Rxn<Offerings> get offerings => _service.offerings;
  RxBool get isOfferingsLoading => _service.isOfferingsLoading;
  bool get hasActiveSubscription => _service.hasActiveSubscription;
  EntitlementInfo? get activeEntitlement => _service.activeEntitlement;
  DateTime? get expirationDate => _service.expirationDate;
  String? get activeProductIdentifier => _service.activeProductIdentifier;

  /// False once the user turns off auto-renew in the store. Null when the
  /// store has no active entitlement for this device's account.
  bool? get willRenew => _service.activeEntitlement?.willRenew;

  List<Package> get availablePackages => _service.availablePackages;

  // ── Lifecycle ───────────────────────────────────────────────────────────────
  @override
  void onInit() {
    super.onInit();
    if (Get.isRegistered<ProfileController>()) {
      Get.find<ProfileController>().refreshProfile();
    }
    loadPurchaseHistory();
  }

  // ── Actions ─────────────────────────────────────────────────────────────────

  /// Subscribe to a [Package] from the RevenueCat offering.
  Future<void> subscribe(Package package) async {
    isLoading.value = true;
    try {
      final outcome = await _service.purchasePackage(package);
      DPrint.log("Subscription button -> $outcome");
      switch (outcome) {
        case PurchaseOutcome.success:
          Get.snackbar(
            'Subscribed',
            'Your subscription is now active. Enjoy!',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
          await loadPurchaseHistory();
        case PurchaseOutcome.cancelled:
          break;
        case PurchaseOutcome.notEntitled:
          Get.snackbar(
            'Payment Processed',
            'Purchase completed but entitlement not found. Please contact support.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.orange,
            colorText: Colors.white,
          );
        case PurchaseOutcome.error:
          Get.snackbar(
            'Purchase Failed',
            'Could not complete the purchase. Please try again.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
      }
    } finally {
      isLoading.value = false;
    }
  }

  /// Restore previously purchased subscriptions.
  Future<void> restorePurchases() async {
    isLoading.value = true;
    try {
      final outcome = await _service.restorePurchases();
      switch (outcome) {
        case PurchaseOutcome.success:
          Get.snackbar(
            'Restored',
            'Your subscription has been restored.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
          await loadPurchaseHistory();
        case PurchaseOutcome.notEntitled:
          Get.snackbar(
            'No Subscription Found',
            'No active subscription to restore.',
            snackPosition: SnackPosition.BOTTOM,
          );
        case PurchaseOutcome.error:
          Get.snackbar(
            'Restore Failed',
            'Could not restore purchases. Please try again.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        case PurchaseOutcome.cancelled:
          break;
      }
    } finally {
      isLoading.value = false;
    }
  }

  static const String _playSubscriptionsUrl =
      'https://play.google.com/store/account/subscriptions';

  /// Open the platform refund page.
  Future<void> requestRefund() async {
    final Uri uri = Platform.isIOS
        ? Uri.parse('https://reportaproblem.apple.com')
        : Uri.parse(_playSubscriptionsUrl);
    await _openOrExplain(uri, 'request a refund');
  }

  /// Opens the platform subscription management page where users can cancel.
  /// iOS → Apple Settings subscriptions page
  /// Android → Google Play subscriptions page
  Future<void> manageSubscription() async {
    final Uri uri = Platform.isIOS
        ? Uri.parse('https://apps.apple.com/account/subscriptions')
        : Uri.parse(_playSubscriptionsUrl);
    await _openOrExplain(uri, 'manage or cancel your subscription');
  }

  /// Opens [uri] in the browser/Play Store. A TV usually has no browser, and
  /// if nothing can open the link the buttons used to silently do nothing —
  /// in both cases, tell the user where to go instead.
  Future<void> _openOrExplain(Uri uri, String action) async {
    if (!TvDevice.isTv) {
      try {
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          return;
        }
      } catch (e) {
        debugPrint('[Subscription] Could not open $uri: $e');
      }
    }
    Get.dialog(
      AlertDialog(
        title: const Text('Google Play subscriptions'),
        content: Text(
          'To $action, open Google Play on your phone or go to '
          '$_playSubscriptionsUrl, signed in with the same Google account.',
        ),
        actions: [
          TextButton(
            autofocus: true,
            onPressed: () => Get.back(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Retry loading offerings if they failed on init.
  Future<void> retryFetchOfferings() async {
    isLoading.value = true;
    await _service.fetchOfferings();
    isLoading.value = false;
  }

  // ── Selection ────────────────────────────────────────────────────────────────
  void selectProduct(String id) =>
      selectedProductId.value = RevenueCatService.baseProductId(id);

  /// Returns the [Package] for a given product ID, or null if not loaded yet.
  Package? getPackageByProductId(String productId) =>
      _service.getPackageByProductId(productId);

  /// True if [productId] is the user's currently active subscription.
  bool isCurrentPlan(String productId) {
    final user = Get.isRegistered<ProfileController>()
        ? Get.find<ProfileController>().userProfile.value
        : null;
    if (user == null || !user.hasActiveSubscription) return false;
    return RevenueCatService.baseProductId(user.subscriptionProductId) ==
        RevenueCatService.baseProductId(productId);
  }

  // ── Purchase History ─────────────────────────────────────────────────────────
  Future<void> loadPurchaseHistory() async {
    isHistoryLoading.value = true;
    final result = await _subscriptionRepo.getSubscriptionHistory();
    result.fold(
      (f) => debugPrint('[Subscription] history load failed: ${f.message}'),
      (success) => purchaseHistory.assignAll(success.data),
    );
    isHistoryLoading.value = false;
  }
}

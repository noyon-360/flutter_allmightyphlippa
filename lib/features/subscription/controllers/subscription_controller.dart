import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutx_core/flutx_core.dart';
import 'package:get/get.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/services/revenuecat_service.dart';
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

  /// Open the platform refund page.
  Future<void> requestRefund() async {
    final Uri uri = Platform.isIOS
        ? Uri.parse('https://reportaproblem.apple.com')
        : Uri.parse('https://play.google.com/store/account/subscriptions');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('[Subscription] Could not open refund page: $e');
    }
  }

  /// Opens the platform subscription management page where users can cancel.
  /// iOS → Apple Settings subscriptions page
  /// Android → Google Play subscriptions page
  Future<void> manageSubscription() async {
    final Uri uri = Platform.isIOS
        ? Uri.parse('https://apps.apple.com/account/subscriptions')
        : Uri.parse('https://play.google.com/store/account/subscriptions');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('[Subscription] Could not open manage page: $e');
    }
  }

  /// Retry loading offerings if they failed on init.
  Future<void> retryFetchOfferings() async {
    isLoading.value = true;
    await _service.fetchOfferings();
    isLoading.value = false;
  }

  // ── Selection ────────────────────────────────────────────────────────────────
  void selectProduct(String id) => selectedProductId.value = id;

  /// Returns the [Package] for a given product ID, or null if not loaded yet.
  Package? getPackageByProductId(String productId) =>
      _service.getPackageByProductId(productId);

  /// True if [productId] is the user's currently active subscription.
  bool isCurrentPlan(String productId) {
    final user = Get.isRegistered<ProfileController>()
        ? Get.find<ProfileController>().userProfile.value
        : null;
    if (user?.subscriptionStatus != 'active') return false;
    return user?.subscriptionProductId == productId;
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

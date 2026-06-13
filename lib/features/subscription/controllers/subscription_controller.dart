import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';

import '../../profile/controller/profile_controller.dart';
import '../repositories/subscription_repo.dart';

class SubscriptionController extends GetxController {
  final _subscriptionRepo = Get.find<SubscriptionRepo>();
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;

  late StreamSubscription<List<PurchaseDetails>> _subscription;

  final products = <ProductDetails>[].obs;
  final isLoading = false.obs;
  final isStoreAvailable = false.obs;

  // Product IDs from App Store Connect
  static const String monthlyId = 'month_subscription';
  static const String quarterlyId = 'premium_quarterly';
  static const String yearlyId = 'premium_t_yearly';

  // Keep private aliases for internal use
  static const String _monthlySubscriptionId = monthlyId;
  static const String _weeklySubscriptionId = quarterlyId;
  static const String _yearlySubscriptionId = yearlyId;

  final selectedProductId = monthlyId.obs;

  @override
  void onInit() {
    super.onInit();
    // Refresh profile so subscriptionStatus/subscriptionProductId are current
    // when the screen opens, which drives the "CURRENT PLAN" badge visibility.
    Get.find<ProfileController>().refreshProfile();
    final purchaseUpdated = _inAppPurchase.purchaseStream;
    _subscription = purchaseUpdated.listen(
      _listenToPurchaseUpdated,
      onDone: () => _subscription.cancel(),
      onError: (error) => debugPrint('Purchase Stream Error: $error'),
    );
    initStore();
  }

  @override
  void onClose() {
    _subscription.cancel();
    super.onClose();
  }

  Future<void> initStore() async {
    final bool available = await _inAppPurchase.isAvailable();
    isStoreAvailable.value = available;

    if (available) {
      await fetchProducts();
    }
  }

  Future<void> fetchProducts() async {
    isLoading.value = true;
    try {
      const Set<String> kIds = <String>{
        _monthlySubscriptionId,
        _weeklySubscriptionId,
        _yearlySubscriptionId,
      };
      final ProductDetailsResponse response = await _inAppPurchase
          .queryProductDetails(kIds);

      if (response.notFoundIDs.isNotEmpty) {
        debugPrint('Products not found: ${response.notFoundIDs}');
      }

      products.assignAll(response.productDetails);
    } catch (e) {
      debugPrint('Error fetching products: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> subscribe(ProductDetails product) async {
    late PurchaseParam purchaseParam;

    if (Platform.isIOS) {
      // For Apple, we might need to handle transition from another subscription
      // but for now simple purchase
      purchaseParam = PurchaseParam(productDetails: product);
      _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
    } else if (Platform.isAndroid) {
      // Future Android implementation
      purchaseParam = PurchaseParam(productDetails: product);
      _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
    }
  }

  Future<void> _listenToPurchaseUpdated(
    List<PurchaseDetails> purchaseDetailsList,
  ) async {
    for (var purchaseDetails in purchaseDetailsList) {
      debugPrint(
        'Purchase Update: ID=${purchaseDetails.productID}, Status=${purchaseDetails.status}',
      );

      if (purchaseDetails.status == PurchaseStatus.pending) {
        isLoading.value = true;
      } else {
        if (purchaseDetails.status == PurchaseStatus.error) {
          debugPrint('Purchase Error: ${purchaseDetails.error}');
          isLoading.value = false;
          Get.snackbar(
            'Error',
            'Purchase failed: ${purchaseDetails.error?.message ?? "Unknown error"}',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        } else if (purchaseDetails.status == PurchaseStatus.canceled) {
          debugPrint('Purchase Canceled by User');
          isLoading.value = false;
          Get.snackbar(
            'Canceled',
            'Payment was canceled.',
            snackPosition: SnackPosition.BOTTOM,
          );
        } else if (purchaseDetails.status == PurchaseStatus.purchased ||
            purchaseDetails.status == PurchaseStatus.restored) {
          debugPrint('Purchase Success/Restored. Verifying...');
          // Verify with backend
          bool verified = await _verifyPurchase(purchaseDetails);

          if (verified) {
            Get.snackbar(
              'Success',
              'Subscription active!',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.green,
              colorText: Colors.white,
            );
            // Refresh profile to update UI with new subscription status
            Get.find<ProfileController>().refreshProfile();
          } else {
            Get.snackbar(
              'Verification Failed',
              'We could not verify your purchase. Please contact support.',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.orange,
              colorText: Colors.white,
            );
          }
        }

        if (purchaseDetails.pendingCompletePurchase) {
          debugPrint('Completing purchase for ${purchaseDetails.productID}');
          await _inAppPurchase.completePurchase(purchaseDetails);
        }
        isLoading.value = false;
      }
    }
  }

  Future<bool> _verifyPurchase(PurchaseDetails purchaseDetails) async {
    if (Platform.isIOS) {
      String? originalTransactionId;

      if (purchaseDetails is SK2PurchaseDetails) {
        // StoreKit 2 (iOS 15+): extract from the JWS payload
        final jws = purchaseDetails.verificationData.serverVerificationData;
        originalTransactionId = _decodeJWSOriginalTransactionId(jws);
      } else if (purchaseDetails is AppStorePurchaseDetails) {
        // StoreKit 1 (legacy): use the payment transaction directly
        originalTransactionId = purchaseDetails
            .skPaymentTransaction
            .originalTransaction
            ?.transactionIdentifier;
      }

      if (originalTransactionId == null) {
        debugPrint('iOS: could not extract originalTransactionId');
        return false;
      }

      final result = await _subscriptionRepo.verifyApplePurchase(
        originalTransactionId,
      );
      return result.fold(
        (failure) {
          debugPrint('Backend Verification Failed: ${failure.message}');
          Get.snackbar('Verification Failed', failure.message);
          return false;
        },
        (success) {
          debugPrint('Backend Verification Success');
          return true;
        },
      );
    }

    if (Platform.isAndroid) {
      final androidDetails = purchaseDetails as GooglePlayPurchaseDetails;
      final purchaseToken =
          androidDetails.billingClientPurchase.purchaseToken;

      const packageName = 'com.almightyflippa.labbytv';

      final result = await _subscriptionRepo.verifyGooglePurchase(
        purchaseToken: purchaseToken,
        subscriptionId: purchaseDetails.productID,
        packageName: packageName,
      );
      return result.fold(
        (failure) {
          debugPrint('Backend Verification Failed: ${failure.message}');
          Get.snackbar('Verification Failed', failure.message);
          return false;
        },
        (success) {
          debugPrint('Backend Verification Success');
          return true;
        },
      );
    }

    return false;
  }

  void selectProduct(String id) => selectedProductId.value = id;

  ProductDetails? getProductById(String id) {
    try {
      return products.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> restorePurchases() async {
    try {
      await _inAppPurchase.restorePurchases();
    } catch (e) {
      debugPrint('Restore failed: $e');
    }
  }

  // Decodes the middle (payload) segment of a JWS token and returns the
  // originalTransactionId field, which the backend verification endpoint expects.
  String? _decodeJWSOriginalTransactionId(String jws) {
    try {
      final parts = jws.split('.');
      if (parts.length < 2) return null;
      var payload = parts[1];
      // base64url has no padding — add it back before decoding
      final remainder = payload.length % 4;
      if (remainder != 0) payload = payload.padRight(payload.length + (4 - remainder), '=');
      final decoded = utf8.decode(base64Url.decode(payload));
      final map = jsonDecode(decoded) as Map<String, dynamic>;
      return map['originalTransactionId']?.toString();
    } catch (e) {
      debugPrint('JWS decode error: $e');
      return null;
    }
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../features/subscription/screens/subscription_screen.dart';
import '../../constants/app_colors.dart';
import '../../services/premium_service.dart';
import '../../services/revenuecat_service.dart';

/// What a free user sees when tapping a Premium-only feature.
abstract final class PremiumUpsell {
  /// The upsell message for a locked feature, or null if it's open.
  ///
  /// [trialIncluded]: the free trial unlocks the feature (PiP). Parental lock
  /// is for paying subscribers only, so trial users get their own message.
  static String? message({
    required String feature,
    required bool trialIncluded,
    required bool isPremium,
    required bool isFreeTrial,
    String? trialLabel,
  }) {
    if (trialIncluded ? isPremium : isPremium && !isFreeTrial) return null;
    if (isFreeTrial) {
      return '$feature is for paid subscribers and isn\'t part of the free '
          'trial. It unlocks automatically when your plan starts.';
    }
    if (trialIncluded && trialLabel != null) {
      return '$feature is a Premium feature. Start your $trialLabel to try it free.';
    }
    if (!trialIncluded && trialLabel != null) {
      return '$feature is for paid Premium subscribers (not included in the '
          'free trial).';
    }
    return '$feature is a Premium feature. Subscribe to unlock it.';
  }

  /// True if the user may use the feature now; otherwise shows the upsell.
  static bool check({required String feature, required bool trialIncluded}) {
    final premium = PremiumService.to;
    final trial = Get.isRegistered<RevenueCatService>()
        ? Get.find<RevenueCatService>().availableFreeTrial
        : null;
    final text = message(
      feature: feature,
      trialIncluded: trialIncluded,
      isPremium: premium.isPremium.value,
      isFreeTrial: premium.isFreeTrial.value,
      trialLabel: trial?.label,
    );
    if (text == null) return true;
    _show(text, onTrial: premium.isFreeTrial.value, trialIncluded: trialIncluded,
        hasTrialOffer: trial != null);
    return false;
  }

  static void _show(
    String text, {
    required bool onTrial,
    required bool trialIncluded,
    required bool hasTrialOffer,
  }) {
    final cta = onTrial
        ? 'View Plans'
        : trialIncluded && hasTrialOffer
        ? 'Start Free Trial'
        : 'See Plans';
    Get.dialog(
      AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.workspace_premium, color: AppColors.red),
            SizedBox(width: 8),
            Text('Premium feature'),
          ],
        ),
        content: Text(text),
        actions: [
          TextButton(onPressed: Get.back, child: const Text('Not now')),
          // Autofocus so a TV remote lands on the main action.
          TextButton(
            autofocus: true,
            onPressed: () {
              Get.back();
              Get.to(() => const SubscriptionScreen());
            },
            child: Text(cta, style: const TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
  }
}

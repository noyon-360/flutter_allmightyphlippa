import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../../core/constants/app_colors.dart';
import '../../auth/models/user_response_model.dart';
import '../../profile/controller/profile_controller.dart';
import '../controllers/subscription_controller.dart';
import 'subscription_history_screen.dart';

class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SubscriptionController>();
    final profileController = Get.find<ProfileController>();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: Colors.white),
            tooltip: 'Purchase History',
            onPressed: () => Get.to(() => const SubscriptionHistoryScreen()),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              const Text(
                'Subscription',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              // Current plan banner driven by profile (no store dependency)
              Obx(
                () => _buildCurrentPlanBanner(
                  profileController.userProfile.value,
                ),
              ),
              const SizedBox(height: 32),

              // Plan cards
              Obx(() {
                final isOfferingsLoading = controller.isOfferingsLoading.value;
                final packages = controller.availablePackages;

                if (isOfferingsLoading) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  );
                }

                if (packages.isEmpty) {
                  return _buildEmptyState(controller);
                }

                const order = [
                  SubscriptionController.monthlyId,
                  SubscriptionController.quarterlyId,
                  SubscriptionController.yearlyId,
                ];
                final sorted = [...packages]
                  ..sort(
                    (a, b) => order
                        .indexOf(a.storeProduct.identifier)
                        .compareTo(order.indexOf(b.storeProduct.identifier)),
                  );

                return Column(
                  children: sorted
                      .map(
                        (pkg) =>
                            Obx(() => _buildSubscriptionCard(pkg, controller)),
                      )
                      .toList(),
                );
              }),

              const SizedBox(height: 8),
              _buildSubscribeButton(controller),
              const SizedBox(height: 8),

              _buildRestoreButton(controller),
              Obx(() {
                final isActive =
                    profileController.userProfile.value?.subscriptionStatus ==
                    'active';
                if (!isActive) return const SizedBox.shrink();
                return _buildManageButton(controller);
              }),
              _buildRefundButton(controller),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // ── Current Plan Banner ─────────────────────────────────────────────────────

  Widget _buildCurrentPlanBanner(UserModel? user) {
    final isActive = user?.subscriptionStatus == 'active';
    if (!isActive) return const SizedBox.shrink();

    final planName = _planNameFromProductId(user?.subscriptionProductId);
    final expiresAt = user?.subscriptionExpiresAt;
    final startDate = user?.subscriptionStartDate;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            AppColors.red.withAlpha((0.85 * 255).toInt()),
            AppColors.red.withAlpha((0.55 * 255).toInt()),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            planName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (startDate != null || expiresAt != null) ...[
            const SizedBox(height: 8),
            if (startDate != null)
              Text(
                'Started: ${_fmtDate(startDate)}',
                style: TextStyle(
                  color: Colors.white.withAlpha((0.8 * 255).toInt()),
                  fontSize: 13,
                ),
              ),
            if (expiresAt != null) ...[
              const SizedBox(height: 2),
              Text(
                'Renews: ${_fmtDate(expiresAt)}',
                style: TextStyle(
                  color: Colors.white.withAlpha((0.8 * 255).toInt()),
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  // ── Empty State ─────────────────────────────────────────────────────────────

  Widget _buildEmptyState(SubscriptionController controller) {
    return Column(
      children: [
        const Icon(Icons.error_outline, color: Colors.grey, size: 48),
        const SizedBox(height: 16),
        const Text(
          'No plans available right now',
          style: TextStyle(color: Colors.white),
        ),
        TextButton(
          onPressed: controller.retryFetchOfferings,
          child: const Text(
            'Try Again',
            style: TextStyle(color: AppColors.red),
          ),
        ),
      ],
    );
  }

  // ── Plan Cards ──────────────────────────────────────────────────────────────

  Widget _buildSubscriptionCard(
    Package package,
    SubscriptionController controller,
  ) {
    final productId = package.storeProduct.identifier;
    final isSelected = controller.selectedProductId.value == productId;
    final isCurrentPlan = controller.isCurrentPlan(productId);
    final isPurchasing = controller.isLoading.value;

    return GestureDetector(
      onTap: isPurchasing ? null : () => controller.selectProduct(productId),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isSelected
              ? AppColors.red.withAlpha((0.12 * 255).toInt())
              : Colors.white.withAlpha((0.04 * 255).toInt()),
          border: Border.all(
            color: isSelected
                ? AppColors.red
                : Colors.white.withAlpha((0.15 * 255).toInt()),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
              child: Row(
                children: [
                  Text(
                    _planNameFromProductId(productId),
                    style: TextStyle(
                      color: isSelected ? AppColors.red : Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.4,
                    ),
                  ),
                  if (isCurrentPlan) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.red.withAlpha((0.2 * 255).toInt()),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Current',
                        style: TextStyle(
                          color: AppColors.red,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected ? AppColors.red : Colors.transparent,
                      border: Border.all(
                        color: isSelected
                            ? AppColors.red
                            : Colors.white.withAlpha((0.3 * 255).toInt()),
                        width: 2,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white, size: 14)
                        : null,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: package.storeProduct.priceString,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        TextSpan(
                          text: ' ${_periodLabel(productId)}',
                          style: TextStyle(
                            color: Colors.white.withAlpha((0.7 * 255).toInt()),
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Divider(color: Colors.white.withAlpha((0.2 * 255).toInt())),
                  const SizedBox(height: 16),
                  _buildFeatureRow('Instant sync across devices'),
                  const SizedBox(height: 12),
                  _buildFeatureRow('Unlimited EPG navigation'),
                  const SizedBox(height: 12),
                  _buildFeatureRow('EPG reminders'),
                  const SizedBox(height: 12),
                  _buildFeatureRow('No watermarks'),
                  const SizedBox(height: 12),
                  _buildFeatureRow('No device limit'),
                  const SizedBox(height: 12),
                  _buildFeatureRow('Offline playback'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureRow(String text) {
    return Row(
      children: [
        const Icon(Icons.check, color: Colors.white, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
      ],
    );
  }

  // ── Subscribe Button ────────────────────────────────────────────────────────

  Widget _buildSubscribeButton(SubscriptionController controller) {
    return Obx(() {
      final selectedId = controller.selectedProductId.value;
      final isCurrentPlan = controller.isCurrentPlan(selectedId);
      final isPurchasing = controller.isLoading.value;
      final selectedPackage = controller.getPackageByProductId(selectedId);

      final bool disabled =
          isCurrentPlan || isPurchasing || selectedPackage == null;

      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: disabled
              ? null
              : () => controller.subscribe(selectedPackage),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.red,
            disabledBackgroundColor: Colors.white.withAlpha(
              (0.1 * 255).toInt(),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: isPurchasing
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Text(
                  isCurrentPlan ? 'Current Plan' : 'Subscribe',
                  style: TextStyle(
                    color: disabled ? Colors.white38 : Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      );
    });
  }

  // ── Restore / Refund ────────────────────────────────────────────────────────

  Widget _buildManageButton(SubscriptionController controller) {
    return TextButton(
      onPressed: controller.manageSubscription,
      child: Text(
        'Manage Subscription',
        style: TextStyle(
          color: Colors.white.withAlpha((0.6 * 255).toInt()),
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildRestoreButton(SubscriptionController controller) {
    return TextButton(
      onPressed: controller.restorePurchases,
      child: Text(
        'Restore Purchases',
        style: TextStyle(
          color: Colors.white.withAlpha((0.5 * 255).toInt()),
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildRefundButton(SubscriptionController controller) {
    return TextButton(
      onPressed: controller.requestRefund,
      child: Text(
        'Request a Refund',
        style: TextStyle(
          color: Colors.white.withAlpha((0.35 * 255).toInt()),
          fontSize: 13,
        ),
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  String _planNameFromProductId(String? productId) => switch (productId) {
    SubscriptionController.monthlyId => 'Monthly Plan',
    SubscriptionController.quarterlyId => 'Quarterly Plan',
    SubscriptionController.yearlyId => 'Yearly Plan',
    _ => 'Premium Plan',
  };

  String _periodLabel(String productId) => switch (productId) {
    SubscriptionController.yearlyId => '/year',
    SubscriptionController.quarterlyId => '/quarter',
    _ => '/month',
  };

  String _fmtDate(DateTime d) => '${d.day} ${_month(d.month)} ${d.year}';

  String _month(int m) => const [
    '',
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ][m];
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../../core/common/widgets/tv_focus_wrapper.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/revenuecat_service.dart';
import '../../auth/models/user_response_model.dart';
import '../../profile/controller/profile_controller.dart';
import '../controllers/subscription_controller.dart';
import 'subscription_history_screen.dart';
import 'package:flutter_almightyflippa/core/config/app_palette.dart';

class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SubscriptionController>();
    final profileController = Get.find<ProfileController>();

    return Scaffold(
      backgroundColor: context.palette.background,
      appBar: AppBar(
        backgroundColor: context.palette.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.adaptive.arrow_back, color: context.palette.textPrimary),
          onPressed: () => Get.back(),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.history, color: context.palette.textPrimary),
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
              Text(
                'Subscription',
                style: TextStyle(
                  color: context.palette.textPrimary,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              // Current plan banner driven by profile (no store dependency)
              Obx(() {
                // Read customerInfo so the banner rebuilds when the store
                // reports an auto-renew change.
                controller.customerInfo.value;
                final user = profileController.userProfile.value;
                return _buildCurrentPlanBanner(
                  context, user,
                  // The store's live answer when this device has the
                  // entitlement; otherwise what the backend last heard.
                  willRenew:
                      controller.willRenew ?? user?.subscriptionWillRenew,
                );
              }),
              const SizedBox(height: 32),

              // Plan cards
              Obx(() {
                final isOfferingsLoading = controller.isOfferingsLoading.value;
                final packages = controller.availablePackages;

                if (isOfferingsLoading) {
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: CircularProgressIndicator(color: context.palette.textPrimary),
                    ),
                  );
                }

                if (packages.isEmpty) {
                  return _buildEmptyState(context, controller);
                }

                const order = [
                  SubscriptionController.monthlyId,
                  SubscriptionController.quarterlyId,
                  SubscriptionController.yearlyId,
                ];
                int rank(Package p) => order.indexOf(
                  RevenueCatService.baseProductId(p.storeProduct.identifier),
                );
                final sorted = [...packages]
                  ..sort((a, b) => rank(a).compareTo(rank(b)));

                return Column(
                  children: sorted
                      .map(
                        (pkg) =>
                            Obx(() => _buildSubscriptionCard(context, pkg, controller)),
                      )
                      .toList(),
                );
              }),

              const SizedBox(height: 8),
              _buildSubscribeButton(context, controller),
              const SizedBox(height: 8),

              _buildRestoreButton(context, controller),
              Obx(() {
                final isActive =
                    profileController
                        .userProfile
                        .value
                        ?.hasActiveSubscription ??
                    false;
                if (!isActive) return const SizedBox.shrink();
                return _buildManageButton(context, controller);
              }),
              _buildRefundButton(context, controller),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // ── Current Plan Banner ─────────────────────────────────────────────────────

  /// Always shows the user's current LABBY membership status — Free,
  /// active Premium, or expired/canceled Premium — so a user never has to
  /// infer their plan from side effects like whether a watermark appears.
  Widget _buildCurrentPlanBanner(BuildContext context, UserModel? user, {bool? willRenew}) {
    final isActive = user?.hasActiveSubscription ?? false;
    // The backend resets plan to "free" on expiry, so an expiry date is the
    // reliable sign that this user had a subscription at some point.
    final wasPremium = user?.subscriptionExpiresAt != null;
    final expiresAt = user?.subscriptionExpiresAt;
    final startDate = user?.subscriptionStartDate;

    final String planName;
    final String statusLabel;
    final Color statusColor;
    final List<Color> gradientColors;

    if (isActive) {
      planName = _planNameFromProductId(user?.subscriptionProductId);
      statusLabel = 'Active';
      statusColor = AppColors.successGreen;
      gradientColors = [
        AppColors.red.withAlpha((0.85 * 255).toInt()),
        AppColors.red.withAlpha((0.55 * 255).toInt()),
      ];
    } else if (wasPremium) {
      planName = _planNameFromProductId(user?.subscriptionProductId);
      statusLabel = 'Expired';
      statusColor = AppColors.red;
      gradientColors = [context.palette.surface, context.palette.surface];
    } else {
      planName = 'Free Plan';
      statusLabel = 'Free';
      statusColor = context.palette.textSecondary;
      gradientColors = [context.palette.surface, context.palette.surface];
    }
    // White reads on the red Premium gradient; the plain cards follow the theme.
    final onBanner = isActive ? Colors.white : context.palette.textPrimary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                planName,
                style: TextStyle(
                  color: onBanner,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withAlpha((0.2 * 255).toInt()),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (startDate != null || expiresAt != null) ...[
            const SizedBox(height: 8),
            if (startDate != null && isActive)
              Text(
                'Started: ${_fmtDate(startDate)}',
                style: TextStyle(
                  color: onBanner.withAlpha((0.8 * 255).toInt()),
                  fontSize: 13,
                ),
              ),
            if (expiresAt != null) ...[
              const SizedBox(height: 2),
              Text(
                '${!isActive
                    ? 'Expired'
                    : willRenew == false
                    ? 'Expires'
                    : 'Renews'}: ${_fmtDate(expiresAt)}',
                style: TextStyle(
                  color: onBanner.withAlpha((0.8 * 255).toInt()),
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

  Widget _buildEmptyState(BuildContext context, SubscriptionController controller) {
    return Column(
      children: [
        const Icon(Icons.error_outline, color: Colors.grey, size: 48),
        const SizedBox(height: 16),
        Text(
          'No plans available right now',
          style: TextStyle(color: context.palette.textPrimary),
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
    BuildContext context, Package package,
    SubscriptionController controller,
  ) {
    // Android identifiers carry the base plan ("month_subscription:monthly-
    // base-plan"); compare and label by the bare product ID.
    final productId = RevenueCatService.baseProductId(
      package.storeProduct.identifier,
    );
    final isSelected = controller.selectedProductId.value == productId;
    final isCurrentPlan = controller.isCurrentPlan(productId);
    final isPurchasing = controller.isLoading.value;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TvFocusWrapper(
        onTap: isPurchasing ? null : () => controller.selectProduct(productId),
        // Remote users start on the preselected plan.
        autofocus: isSelected,
        borderRadius: 18,
        focusColor: context.palette.textPrimary,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: isSelected
                ? AppColors.red.withAlpha((0.12 * 255).toInt())
                : context.palette.textPrimary.withAlpha((0.04 * 255).toInt()),
            border: Border.all(
              color: isSelected
                  ? AppColors.red
                  : context.palette.textPrimary.withAlpha((0.15 * 255).toInt()),
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
                        color: isSelected ? AppColors.red : context.palette.textPrimary.withValues(alpha: 0.70),
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
                              : context.palette.textPrimary.withAlpha((0.3 * 255).toInt()),
                          width: 2,
                        ),
                      ),
                      child: isSelected
                          ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 14,
                            )
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
                            style: TextStyle(
                              color: context.palette.textPrimary,
                              fontSize: 36,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          TextSpan(
                            text: ' ${_periodLabel(productId)}',
                            style: TextStyle(
                              color: context.palette.textPrimary.withAlpha(
                                (0.7 * 255).toInt(),
                              ),
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Divider(color: context.palette.textPrimary.withAlpha((0.2 * 255).toInt())),
                    const SizedBox(height: 16),
                    _buildFeatureRow(context, 'Instant sync across devices'),
                    const SizedBox(height: 12),
                    _buildFeatureRow(context, 'Unlimited EPG navigation'),
                    const SizedBox(height: 12),
                    _buildFeatureRow(context, 'EPG reminders'),
                    const SizedBox(height: 12),
                    _buildFeatureRow(context, 'No watermarks'),
                    const SizedBox(height: 12),
                    _buildFeatureRow(context, 'No device limit'),
                    const SizedBox(height: 12),
                    _buildFeatureRow(context, 'Offline playback'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureRow(BuildContext context, String text) {
    return Row(
      children: [
        Icon(Icons.check, color: context.palette.textPrimary, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: context.palette.textPrimary, fontSize: 16),
          ),
        ),
      ],
    );
  }

  // ── Subscribe Button ────────────────────────────────────────────────────────

  Widget _buildSubscribeButton(BuildContext context, SubscriptionController controller) {
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
            disabledBackgroundColor: context.palette.textPrimary.withAlpha(
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
                    color: disabled
                        ? context.palette.textPrimary.withValues(alpha: 0.38)
                        : Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      );
    });
  }

  // ── Restore / Refund ────────────────────────────────────────────────────────

  Widget _buildManageButton(BuildContext context, SubscriptionController controller) {
    return TextButton(
      onPressed: controller.manageSubscription,
      child: Text(
        'Manage Subscription',
        style: TextStyle(
          color: context.palette.textPrimary.withAlpha((0.6 * 255).toInt()),
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildRestoreButton(BuildContext context, SubscriptionController controller) {
    return TextButton(
      onPressed: controller.restorePurchases,
      child: Text(
        'Restore Purchases',
        style: TextStyle(
          color: context.palette.textPrimary.withAlpha((0.5 * 255).toInt()),
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildRefundButton(BuildContext context, SubscriptionController controller) {
    return TextButton(
      onPressed: controller.requestRefund,
      child: Text(
        'Request a Refund',
        style: TextStyle(
          color: context.palette.textPrimary.withAlpha((0.35 * 255).toInt()),
          fontSize: 13,
        ),
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  String _planNameFromProductId(String? productId) =>
      switch (RevenueCatService.baseProductId(productId)) {
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

  // Backend dates arrive as UTC; show them in the user's own timezone.
  String _fmtDate(DateTime d) {
    final local = d.toLocal();
    return '${local.day} ${_month(local.month)} ${local.year}';
  }

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

import 'package:flutter/material.dart';
import 'package:flutx_core/flutx_core.dart';
import 'package:get/get.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/models/user_response_model.dart';
import '../../profile/controller/profile_controller.dart';
import '../controllers/subscription_controller.dart';
import '../models/subscription_history_model.dart';

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

              // Always-visible current plan banner (profile-driven, no store dependency)
              // Obx(() => _buildCurrentPlanBanner(profileController.userProfile.value)),
              const SizedBox(height: 32),

              // Store plan cards
              Obx(() {
                if (controller.isLoading.value) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  );
                }

                if (controller.products.isEmpty) {
                  return _buildEmptyState(controller);
                }

                final order = [
                  SubscriptionController.monthlyId,
                  SubscriptionController.quarterlyId,
                  SubscriptionController.yearlyId,
                ];
                final sorted = [...controller.products]
                  ..sort(
                    (a, b) =>
                        order.indexOf(a.id).compareTo(order.indexOf(b.id)),
                  );
                return Column(
                  children: sorted.map((product) {
                    DPrint.log("product price ${product.price}");
                    DPrint.log("product description ${product.description}");
                    DPrint.log("product id ${product.id}");
                    DPrint.log("product title ${product.title}");
                    return Obx(
                      () => _buildSubscriptionCard(
                        product,
                        controller,
                        profileController,
                      ),
                    );
                  }).toList(),
                );
              }),

              _buildRestoreButton(controller),
              _buildRefundButton(controller),
              const SizedBox(height: 32),
              _buildPurchaseHistory(controller),
              const SizedBox(height: 20),
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

  String _planNameFromProductId(String? productId) {
    switch (productId) {
      case SubscriptionController.monthlyId:
        return 'Monthly Plan';
      case SubscriptionController.quarterlyId:
        return 'Quarterly Plan';
      case SubscriptionController.yearlyId:
        return 'Yearly Plan';
      default:
        return 'Premium Plan';
    }
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
          onPressed: controller.fetchProducts,
          child: const Text(
            'Try Again',
            style: TextStyle(color: AppColors.red),
          ),
        ),
      ],
    );
  }

  // ── Plan Cards ──────────────────────────────────────────────────────────────

  String _periodLabel(String productId) {
    if (productId == SubscriptionController.yearlyId) return '/year';
    if (productId == SubscriptionController.quarterlyId) return '/quarter';
    return '/month';
  }

  bool _isCurrentPlan(String productId, ProfileController profileController) {
    final user = profileController.userProfile.value;
    if (user?.subscriptionStatus != 'active') return false;
    return user?.subscriptionProductId == productId;
  }

  Widget _buildSubscriptionCard(
    ProductDetails product,
    SubscriptionController controller,
    ProfileController profileController,
  ) {
    final bool isActive = _isCurrentPlan(product.id, profileController);

    DPrint.log("isActive id $isActive");
    DPrint.log("product title ${product.title}");
    DPrint.log("product description ${product.description}");
    DPrint.log("product price ${product.price}");

    return GestureDetector(
      onTap: isActive
          ? () => Get.snackbar(
              'Already Subscribed',
              'You are currently on this plan.',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.white,
              colorText: Colors.black,
            )
          : () => controller.subscribe(product),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isActive
              ? AppColors.red.withAlpha((0.12 * 255).toInt())
              : Colors.white.withAlpha((0.04 * 255).toInt()),
          border: Border.all(
            color: isActive
                ? AppColors.red
                : Colors.white.withAlpha((0.15 * 255).toInt()),
            width: isActive ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            // Header row: plan label on left, check indicator on right
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
              child: Row(
                children: [
                  Text(
                    _planNameFromProductId(product.id),
                    style: TextStyle(
                      color: isActive ? AppColors.red : Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isActive ? AppColors.red : Colors.transparent,
                      border: Border.all(
                        color: isActive
                            ? AppColors.red
                            : Colors.white.withAlpha((0.3 * 255).toInt()),
                        width: 2,
                      ),
                    ),
                    child: isActive
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
                          text: product.price,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        TextSpan(
                          text: ' ${_periodLabel(product.id)}',
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

  // ── Restore ─────────────────────────────────────────────────────────────────

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

  // ── Purchase History ────────────────────────────────────────────────────────

  Widget _buildPurchaseHistory(SubscriptionController controller) {
    return Obx(() {
      if (controller.isHistoryLoading.value) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Center(child: CircularProgressIndicator(color: Colors.white)),
        );
      }

      final history = controller.purchaseHistory;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Purchase History',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (history.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'No purchase history found.',
                style: TextStyle(
                  color: Colors.white.withAlpha((0.5 * 255).toInt()),
                  fontSize: 14,
                ),
              ),
            )
          else
            ...history.map(_buildHistoryCard),
        ],
      );
    });
  }

  Widget _buildHistoryCard(SubscriptionHistoryModel item) {
    final Color statusColor;
    final String statusLabel;

    switch (item.status) {
      case 'active':
        statusColor = Colors.green;
        statusLabel = 'Active';
        break;
      case 'refunded':
        statusColor = Colors.orange;
        statusLabel = 'Refunded';
        break;
      default:
        statusColor = Colors.white54;
        statusLabel = 'Expired';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white.withAlpha((0.05 * 255).toInt()),
        border: Border.all(color: Colors.white.withAlpha((0.15 * 255).toInt())),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: statusColor.withAlpha((0.15 * 255).toInt()),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.workspace_premium,
              color: statusColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.planLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (item.startDate != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    _formatDateRange(item.startDate, item.endDate),
                    style: TextStyle(
                      color: Colors.white.withAlpha((0.55 * 255).toInt()),
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withAlpha((0.15 * 255).toInt()),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: statusColor.withAlpha((0.5 * 255).toInt())),
            ),
            child: Text(
              statusLabel,
              style: TextStyle(
                color: statusColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  String _fmtDate(DateTime d) => '${d.day} ${_month(d.month)} ${d.year}';

  String _formatDateRange(DateTime? start, DateTime? end) {
    if (start != null && end != null) {
      return '${_fmtDate(start)} – ${_fmtDate(end)}';
    }
    if (start != null) return 'Since ${_fmtDate(start)}';
    return '';
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

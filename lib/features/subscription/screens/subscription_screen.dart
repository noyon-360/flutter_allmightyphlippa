import 'package:flutter/material.dart';
import 'package:flutx_core/flutx_core.dart';
import 'package:get/get.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../../../core/constants/app_colors.dart';
import '../../profile/controller/profile_controller.dart';
import '../controllers/subscription_controller.dart';

class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SubscriptionController());
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
              const SizedBox(height: 60),
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
                    return _buildSubscriptionCard(
                      product,
                      controller,
                      profileController,
                    );
                  }).toList(),
                );
              }),
              _buildRestoreButton(controller),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

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

  String _periodLabel(String productId) {
    if (productId == SubscriptionController.yearlyId) return '/year';
    if (productId == SubscriptionController.quarterlyId) return '/quarter';
    return '/month';
  }

  bool _isCurrentPlan(String productId, ProfileController profileController) {
    final user = profileController.userProfile.value;
    if (user?.subscriptionStatus != 'active') return false;
    final plan = (user?.plan ?? '').toLowerCase();
    if (productId == SubscriptionController.monthlyId) {
      return plan.contains('month') || plan == SubscriptionController.monthlyId;
    }
    if (productId == SubscriptionController.quarterlyId) {
      return plan.contains('quarter') ||
          plan == SubscriptionController.quarterlyId;
    }
    if (productId == SubscriptionController.yearlyId) {
      return plan.contains('year') ||
          plan.contains('annual') ||
          plan == SubscriptionController.yearlyId;
    }
    return false;
  }

  Widget _buildSubscriptionCard(
    ProductDetails product,
    SubscriptionController controller,
    ProfileController profileController,
  ) {
    final bool isActive = _isCurrentPlan(product.id, profileController);

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
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: isActive
              ? AppColors.red.withAlpha((0.1 * 255).toInt())
              : Colors.transparent,
          border: Border.all(
            color: isActive
                ? AppColors.red
                : Colors.white.withAlpha((0.5 * 255).toInt()),
            width: isActive ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            if (isActive)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.red,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'CURRENT PLAN',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
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
}

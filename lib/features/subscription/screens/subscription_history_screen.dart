import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/subscription_controller.dart';
import '../models/subscription_history_model.dart';
import 'package:flutter_almightyflippa/core/config/app_palette.dart';

class SubscriptionHistoryScreen extends StatelessWidget {
  const SubscriptionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SubscriptionController>();

    return Scaffold(
      backgroundColor: context.palette.background,
      appBar: AppBar(
        backgroundColor: context.palette.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.adaptive.arrow_back, color: context.palette.textPrimary),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Purchase History',
          style: TextStyle(color: context.palette.textPrimary, fontWeight: FontWeight.bold),
        ),
      ),
      body: Obx(() {
        if (controller.isHistoryLoading.value) {
          return Center(
            child: CircularProgressIndicator(color: context.palette.textPrimary),
          );
        }

        final history = controller.purchaseHistory;

        if (history.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  color: context.palette.textPrimary.withAlpha((0.3 * 255).toInt()),
                  size: 64,
                ),
                const SizedBox(height: 16),
                Text(
                  'No purchase history found.',
                  style: TextStyle(
                    color: context.palette.textPrimary.withAlpha((0.5 * 255).toInt()),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          color: context.palette.textPrimary,
          backgroundColor: context.palette.surface,
          onRefresh: controller.loadPurchaseHistory,
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            itemCount: history.length,
            itemBuilder: (context, index) =>
                _buildHistoryCard(context, history[index]),
          ),
        );
      }),
    );
  }

  Widget _buildHistoryCard(BuildContext context, SubscriptionHistoryModel item) {
    final Color statusColor;
    final String statusLabel;

    switch (item.effectiveStatus) {
      case 'active':
        statusColor = Colors.green;
        statusLabel = 'Active';
      case 'refunded':
        statusColor = Colors.orange;
        statusLabel = 'Refunded';
      case 'canceled':
        statusColor = context.palette.textPrimary.withValues(alpha: 0.54);
        statusLabel = 'Canceled';
      default:
        statusColor = context.palette.textPrimary.withValues(alpha: 0.54);
        statusLabel = 'Expired';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: context.palette.textPrimary.withAlpha((0.05 * 255).toInt()),
        border: Border.all(color: context.palette.textPrimary.withAlpha((0.15 * 255).toInt())),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: statusColor.withAlpha((0.15 * 255).toInt()),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.workspace_premium, color: statusColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.isTrial ? '${item.planLabel} · Free trial' : item.planLabel,
                  style: TextStyle(
                    color: context.palette.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (item.startDate != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    _formatDateRange(item.startDate, item.endDate),
                    style: TextStyle(
                      color: context.palette.textPrimary.withAlpha((0.55 * 255).toInt()),
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
              border: Border.all(
                color: statusColor.withAlpha((0.5 * 255).toInt()),
              ),
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

  String _formatDateRange(DateTime? start, DateTime? end) {
    if (start != null && end != null) {
      return '${_fmtDate(start)} – ${_fmtDate(end)}';
    }
    if (start != null) return 'Since ${_fmtDate(start)}';
    return '';
  }

  // Backend dates arrive as UTC; show them in the user's own timezone.
  String _fmtDate(DateTime d) {
    final local = d.toLocal();
    return '${local.day} ${_month(local.month)} ${local.year}';
  }

  String _month(int m) => const [
    '',
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ][m];
}

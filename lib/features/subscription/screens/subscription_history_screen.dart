import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/subscription_controller.dart';
import '../models/subscription_history_model.dart';

class SubscriptionHistoryScreen extends StatelessWidget {
  const SubscriptionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SubscriptionController>();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Purchase History',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Obx(() {
        if (controller.isHistoryLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
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
                  color: Colors.white.withAlpha((0.3 * 255).toInt()),
                  size: 64,
                ),
                const SizedBox(height: 16),
                Text(
                  'No purchase history found.',
                  style: TextStyle(
                    color: Colors.white.withAlpha((0.5 * 255).toInt()),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          color: Colors.white,
          backgroundColor: Colors.grey[900],
          onRefresh: controller.loadPurchaseHistory,
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            itemCount: history.length,
            itemBuilder: (context, index) =>
                _buildHistoryCard(history[index]),
          ),
        );
      }),
    );
  }

  Widget _buildHistoryCard(SubscriptionHistoryModel item) {
    final Color statusColor;
    final String statusLabel;

    switch (item.status) {
      case 'active':
        statusColor = Colors.green;
        statusLabel = 'Active';
      case 'refunded':
        statusColor = Colors.orange;
        statusLabel = 'Refunded';
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
            child: Icon(Icons.workspace_premium, color: statusColor, size: 22),
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

  String _fmtDate(DateTime d) => '${d.day} ${_month(d.month)} ${d.year}';

  String _month(int m) => const [
    '',
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ][m];
}

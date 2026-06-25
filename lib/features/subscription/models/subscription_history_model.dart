class SubscriptionHistoryModel {
  final String? status;
  final String? plan;
  final String? productId;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? platform;

  const SubscriptionHistoryModel({
    this.status,
    this.plan,
    this.productId,
    this.startDate,
    this.endDate,
    this.platform,
  });

  bool get isActive => status == 'active';

  String get planLabel {
    switch (productId) {
      case 'month_subscription':
        return 'Monthly';
      case 'premium_quarterly':
        return 'Quarterly';
      case 'premium_t_yearly':
        return 'Yearly';
      default:
        return plan ?? 'Unknown';
    }
  }

  factory SubscriptionHistoryModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionHistoryModel(
      status: json['status'] ?? json['subscriptionStatus'],
      plan: json['plan'],
      productId: json['productId'] ?? json['subscriptionProductId'],
      platform: json['platform'] ?? json['subscriptionPlatform'],
      startDate: _parseDate(
        json['startDate'] ?? json['subscriptionStartDate'] ?? json['createdAt'],
      ),
      endDate: _parseDate(
        json['expiresAt'] ??
            json['subscriptionExpiresAt'] ??
            json['endDate'] ??
            json['subscriptionEndDate'],
      ),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}

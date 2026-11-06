class SubscriptionHistoryModel {
  final String? status;
  final String? plan;
  final String? productId;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? platform;

  /// The period was a store free trial (backend `isTrial`, missing on older rows).
  final bool isTrial;

  const SubscriptionHistoryModel({
    this.isTrial = false,
    this.status,
    this.plan,
    this.productId,
    this.startDate,
    this.endDate,
    this.platform,
  });

  bool get isActive => effectiveStatus == 'active';

  /// The stored status, except an "active" row whose period has already
  /// ended reads as "expired" — older rows were never updated on expiry.
  String? get effectiveStatus {
    final end = endDate;
    if (status == 'active' && end != null && end.isBefore(DateTime.now())) {
      return 'expired';
    }
    return status;
  }

  String get planLabel {
    // Older rows may hold Android's "product:basePlan" form.
    switch (productId?.split(':').first) {
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
      isTrial: json['isTrial'] == true,
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

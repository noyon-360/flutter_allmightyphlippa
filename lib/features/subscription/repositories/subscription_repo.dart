import 'package:flutter_almightyflippa/core/constants/api_constants.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/network_result.dart';
import '../models/subscription_history_model.dart';

class SubscriptionRepo {
  final ApiClient _apiClient = ApiClient();

  NetworkResult<Map<String, dynamic>> verifyApplePurchase(
    String originalTransactionId,
  ) async {
    return await _apiClient.post(
      endpoint: ApiConstants.payment.verifyApplePurchase,
      data: {'originalTransactionId': originalTransactionId},
      fromJsonT: (json) => json,
    );
  }

  NetworkResult<Map<String, dynamic>> verifyGooglePurchase({
    required String purchaseToken,
    required String subscriptionId,
    required String packageName,
  }) async {
    return await _apiClient.post(
      endpoint: ApiConstants.payment.verifyGooglePurchase,
      data: {
        'purchaseToken': purchaseToken,
        'subscriptionId': subscriptionId,
        'packageName': packageName,
      },
      fromJsonT: (json) => json,
    );
  }

  NetworkResult<Map<String, dynamic>> getSubscriptionStatus() async {
    return await _apiClient.get(
      endpoint: ApiConstants.payment.getMySubscription,
      fromJsonT: (json) => json,
    );
  }

  NetworkResult<List<SubscriptionHistoryModel>> getSubscriptionHistory() async {
    return await _apiClient.get(
      endpoint: ApiConstants.payment.getSubscriptionHistory,
      fromJsonT: (json) {
        if (json is List) {
          return json
              .whereType<Map<String, dynamic>>()
              .map(SubscriptionHistoryModel.fromJson)
              .toList();
        }
        return <SubscriptionHistoryModel>[];
      },
    );
  }
}

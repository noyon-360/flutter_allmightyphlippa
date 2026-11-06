import 'package:dio/dio.dart';
import 'package:flutter_almightyflippa/core/api/network_result.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/network_stream.dart';
import '../../../core/constants/api_constants.dart';
import '../../auth/models/user_response_model.dart';
import 'profile_repo.dart';

class ProfileRepoImpl implements ProfileRepo {
  final ApiClient apiClient;

  ProfileRepoImpl({required this.apiClient});

  @override
  NetworkStream<UserModel> getProfile({bool forceRefresh = false}) {
    return apiClient.getStream<UserModel>(
      endpoint: ApiConstants.user.profile,
      cacheDuration: const Duration(days: 30),
      forceEmitRemote: forceRefresh,
      fromJsonT: (json) => UserModel.fromJson(json),
    );
  }

  @override
  NetworkResult<UserModel> updateProfile({required FormData formData}) async {
    return await apiClient.put<UserModel>(
      endpoint: ApiConstants.user.profile,
      data: formData,
      fromJsonT: (json) => UserModel.fromJson(json),
      // v--- ADD THIS TO CLEAR THE CACHE ---v
      invalidatePaths: [ApiConstants.user.profile],
    );
  }
}

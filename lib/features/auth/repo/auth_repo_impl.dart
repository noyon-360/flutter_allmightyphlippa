import 'package:flutter_almightyflippa/core/api/api_client.dart';
import 'package:flutter_almightyflippa/core/api/network_result.dart';
import 'package:flutter_almightyflippa/core/constants/api_constants.dart';
import 'package:flutter_almightyflippa/features/auth/models/login_request_model.dart';
import 'package:flutter_almightyflippa/features/auth/repo/auth_repo.dart';

import '../models/login_response_model.dart';
import '../models/register_request_model.dart';
import '../models/user_response_model.dart';

class AuthRepoImpl implements AuthRepo {
  final ApiClient _apiClient;
  AuthRepoImpl({required ApiClient apiClient}) : _apiClient = apiClient;

  @override
  NetworkResult<LoginData> login(LoginRequestModel request) {
    return _apiClient.post(
      endpoint: ApiConstants.auth.login,
      data: request.toJson(),
      fromJsonT: (json) => LoginData.fromJson(json),
    );
  }

  @override
  NetworkResult<UserModel> register(RegisterRequestModel request) {
    return _apiClient.post(
      endpoint: ApiConstants.auth.register,
      data: request.toJson(),
      fromJsonT: (json) => UserModel.fromJson(json),
    );
  }
}

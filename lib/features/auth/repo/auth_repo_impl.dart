import 'package:flutter_almightyflippa/core/api/api_client.dart';
import 'package:flutter_almightyflippa/core/api/network_result.dart';
import 'package:flutter_almightyflippa/core/constants/api_constants.dart';
import 'package:flutter_almightyflippa/features/auth/models/change_password_request_model.dart';
import 'package:flutter_almightyflippa/features/auth/models/login_request_model.dart';
import 'package:flutter_almightyflippa/features/auth/repo/auth_repo.dart';

import '../models/login_response_model.dart';
import '../models/register_request_model.dart';
import '../models/tv_login_models.dart';
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

  @override
  NetworkResult<void> changePassword(ChangePasswordRequestModel request) {
    return _apiClient.post(
      endpoint: ApiConstants.auth.changePassword,
      data: request.toJson(),
      fromJsonT: (json) => {},
    );
  }

  @override
  NetworkResult<void> forgetPassword(String email) {
    return _apiClient.post(
      endpoint: ApiConstants.auth.forgetPassSendOtp,
      data: {'email': email},
      fromJsonT: (json) => {},
    );
  }

  @override
  NetworkResult<void> resetPassword({
    required String email,
    required String otp,
    required String password,
  }) {
    return _apiClient.post(
      endpoint: ApiConstants.auth.resetPass,
      // The backend compares the OTP with `!==` against a string, so it must
      // be sent as a string, never parsed to an int.
      data: {'email': email, 'otp': otp, 'password': password},
      fromJsonT: (json) => {},
    );
  }

  @override
  NetworkResult<void> deleteAccount() {
    return _apiClient.delete(
      endpoint: ApiConstants.user.deleteAccount,
      fromJsonT: (json) => {},
    );
  }

  @override
  NetworkResult<TvLoginCode> requestTvLoginCode({
    required String deviceId,
    required String deviceName,
  }) {
    return _apiClient.post(
      endpoint: ApiConstants.auth.tvCode,
      data: {'deviceId': deviceId, 'deviceName': deviceName},
      fromJsonT: (json) => TvLoginCode.fromJson(json),
    );
  }

  @override
  NetworkResult<TvLoginPollResult> pollTvLogin(String deviceCode) {
    return _apiClient.post(
      endpoint: ApiConstants.auth.tvPoll,
      data: {'deviceCode': deviceCode},
      fromJsonT: (json) => TvLoginPollResult.fromJson(json),
    );
  }

  @override
  NetworkResult<void> approveTvLogin({
    required String userCode,
    required bool approve,
  }) {
    return _apiClient.post(
      endpoint: ApiConstants.auth.tvApprove,
      data: {'userCode': userCode, 'approve': approve},
      fromJsonT: (json) => {},
    );
  }
}

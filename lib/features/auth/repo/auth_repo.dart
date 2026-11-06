import '../models/change_password_request_model.dart';
import '../models/login_response_model.dart'; // This now contains LoginData
import '../models/register_request_model.dart';
import '../models/tv_login_models.dart';
import '../models/user_response_model.dart';
import '/core/api/network_result.dart';
import '/features/auth/models/login_request_model.dart';

abstract class AuthRepo {
  NetworkResult<LoginData> login(LoginRequestModel request);
  NetworkResult<UserModel> register(RegisterRequestModel request);
  NetworkResult<void> changePassword(ChangePasswordRequestModel request);
  NetworkResult<void> deleteAccount();
  NetworkResult<void> forgetPassword(String email);
  NetworkResult<void> resetPassword({
    required String email,
    required String otp,
    required String password,
  });

  // Sign in on a TV with a phone.
  NetworkResult<TvLoginCode> requestTvLoginCode({
    required String deviceId,
    required String deviceName,
  });
  NetworkResult<TvLoginPollResult> pollTvLogin(String deviceCode);
  NetworkResult<void> approveTvLogin({
    required String userCode,
    required bool approve,
  });
}

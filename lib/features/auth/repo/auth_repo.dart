import '../models/login_response_model.dart'; // This now contains LoginData
import '../models/register_request_model.dart';
import '../models/user_response_model.dart';
import '/core/api/network_result.dart';
import '/features/auth/models/login_request_model.dart';

abstract class AuthRepo {
  NetworkResult<LoginData> login(LoginRequestModel request);
  NetworkResult<UserModel> register(RegisterRequestModel request);
}

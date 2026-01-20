import '../../../core/api/network_result.dart';
import '../../auth/models/user_response_model.dart';

abstract class ProfileRepo {
  NetworkResult<UserModel> getProfile();
}

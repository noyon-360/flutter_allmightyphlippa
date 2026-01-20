import '../../../core/api/api_client.dart';
import '../../../core/api/network_result.dart';
import '../../../core/constants/api_constants.dart';
import '../../auth/models/user_response_model.dart';
import 'profile_repo.dart';

class ProfileRepoImpl implements ProfileRepo {
  final ApiClient apiClient;

  ProfileRepoImpl({required this.apiClient});

  @override
  NetworkResult<UserModel> getProfile() async {
    return await apiClient.get<UserModel>(
      endpoint: ApiConstants.user.profile,
      fromJsonT: (json) => UserModel.fromJson(json),
    );
  }
}

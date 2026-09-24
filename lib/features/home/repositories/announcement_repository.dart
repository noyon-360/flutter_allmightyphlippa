import '../../../core/api/api_client.dart';
import '../../../core/api/network_result.dart';
import '../../../core/constants/api_constants.dart';
import '../models/announcement_model.dart';

class AnnouncementRepository {
  final ApiClient _apiClient = ApiClient();

  /// The announcements to show right now (active, in their date window,
  /// highest priority first).
  NetworkResult<List<AnnouncementModel>> getActive() async {
    return await _apiClient.get(
      endpoint: ApiConstants.announcement.active,
      fromJsonT: (json) {
        if (json is List) {
          return json
              .whereType<Map<String, dynamic>>()
              .map(AnnouncementModel.fromJson)
              .toList();
        }
        return <AnnouncementModel>[];
      },
    );
  }
}

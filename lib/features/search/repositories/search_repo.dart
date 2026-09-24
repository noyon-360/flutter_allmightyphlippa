import '../../playlist/models/server_request_model.dart';
import '/core/api/network_result.dart';

abstract class SearchRepo {
  NetworkResult<List<T>> search<T>({
    required int page,
    required int limit,
    required String query,
    required ServerType type,
    required T Function(Map<String, dynamic>) fromJson,

    /// Only titles with this person in the cast (an empty [query] is fine).
    String? cast,
  });
}

import 'package:get/get.dart';

import '../repositories/cast_photo_repository.dart';

/// Remembers actor photos for the session so the same face isn't fetched for
/// every title (actors appear on many). A null photo is remembered too, so
/// unknown names aren't asked about again.
class CastPhotoService extends GetxService {
  static CastPhotoService get to => Get.isRegistered<CastPhotoService>()
      ? Get.find<CastPhotoService>()
      : Get.put(CastPhotoService(), permanent: true);

  final CastPhotoRepository _repo = CastPhotoRepository();

  /// name -> photo URL, or null once looked up with no result.
  final RxMap<String, String?> photos = <String, String?>{}.obs;
  final Set<String> _requested = {};

  String? photoFor(String name) => photos[name];

  /// Looks up any of [names] not asked about yet. Failures are quiet: the UI
  /// simply keeps showing initials.
  Future<void> ensureLoaded(List<String> names) async {
    final missing = names.where(_requested.add).toList();
    if (missing.isEmpty) return;

    final result = await _repo.getPhotos(missing);
    result.fold(
      (_) => _requested.removeAll(missing), // allow a retry next time
      (success) {
        for (final name in missing) {
          photos[name] = success.data[name];
        }
      },
    );
  }
}

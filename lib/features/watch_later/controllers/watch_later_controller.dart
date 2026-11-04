import 'package:get/get.dart';

import '../../playlist/services/active_playlist_service.dart';
import '../models/watch_later_item.dart';
import '../repositories/watch_later_repo.dart';

enum WatchLaterScope { thisPlaylist, all }

/// What tapping an item should do.
enum WatchLaterOpenAction {
  /// Saved on the active playlist: play it.
  play,

  /// Saved on another playlist: offer to switch, search here, or remove.
  otherPlaylist,

  /// Its playlist no longer exists, so it can only be removed.
  playlistGone,
}

class WatchLaterController extends GetxController {
  WatchLaterController({
    WatchLaterRepo? repo,
    Future<String?> Function()? resolveActivePlaylistId,
  }) : _repo = repo ?? Get.find<WatchLaterRepo>(),
       _resolveActivePlaylistId =
           resolveActivePlaylistId ??
           ActivePlaylistService().activePlaylistId;

  final WatchLaterRepo _repo;
  final Future<String?> Function() _resolveActivePlaylistId;

  final items = <WatchLaterItem>[].obs;
  final scope = WatchLaterScope.thisPlaylist.obs;
  final activePlaylistId = RxnString();
  final isLoading = false.obs;
  final isMoreLoading = false.obs;
  final hasMore = true.obs;
  final errorMessage = RxnString();

  static const int pageSize = 20;
  int _page = 1;

  // Switching tabs while a page is loading must not let the old tab's
  // response land in the new tab's list.
  int _generation = 0;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  void setScope(WatchLaterScope value) {
    if (scope.value == value) return;
    scope.value = value;
    load();
  }

  Future<void> load({bool isLoadMore = false}) async {
    if (isLoadMore) {
      if (isLoading.value || isMoreLoading.value || !hasMore.value) return;
      isMoreLoading.value = true;
    } else {
      _page = 1;
      hasMore.value = true;
      errorMessage.value = null;
      isLoading.value = true;
    }
    final generation = isLoadMore ? _generation : ++_generation;

    activePlaylistId.value ??= await _resolveActivePlaylistId();
    if (_superseded(generation, isLoadMore)) return;

    final activeId = activePlaylistId.value;
    if (scope.value == WatchLaterScope.thisPlaylist && activeId == null) {
      // No playlist selected (or it can't be identified): nothing can be
      // "on this playlist", and asking without a filter would show them all.
      items.clear();
      hasMore.value = false;
      _finish(isLoadMore);
      return;
    }

    final result = await _repo.getWatchLater(
      playlistId: scope.value == WatchLaterScope.thisPlaylist ? activeId : null,
      page: _page,
      limit: pageSize,
    );
    if (_superseded(generation, isLoadMore)) return;

    result.fold(
      (fail) {
        if (!isLoadMore) errorMessage.value = fail.message;
      },
      (success) {
        final page = success.data;
        if (page.length < pageSize) hasMore.value = false;
        if (isLoadMore) {
          // Something added or removed meanwhile shifts the pages.
          final seen = items.map((e) => e.id).toSet();
          items.addAll(page.where((e) => seen.add(e.id)));
        } else {
          items.assignAll(page);
        }
        _page++;
      },
    );
    _finish(isLoadMore);
  }

  /// A newer full load owns the list (and the main spinner) now; a stale
  /// load-more only has to put its own spinner away.
  bool _superseded(int generation, bool isLoadMore) {
    if (generation == _generation) return false;
    if (isLoadMore) isMoreLoading.value = false;
    return true;
  }

  void _finish(bool isLoadMore) {
    if (isLoadMore) {
      isMoreLoading.value = false;
    } else {
      isLoading.value = false;
    }
  }

  WatchLaterOpenAction actionFor(WatchLaterItem item) =>
      resolveAction(item, activePlaylistId.value);

  static WatchLaterOpenAction resolveAction(
    WatchLaterItem item,
    String? activePlaylistId,
  ) {
    if (item.playlistId == null) return WatchLaterOpenAction.playlistGone;
    if (item.playlistId == activePlaylistId) return WatchLaterOpenAction.play;
    return WatchLaterOpenAction.otherPlaylist;
  }

  Future<bool> remove(WatchLaterItem item) async {
    final index = items.indexWhere((e) => e.id == item.id);
    if (index >= 0) items.removeAt(index);

    final result = await _repo.remove(item.id);
    return result.fold((fail) {
      if (index >= 0 && !items.any((e) => e.id == item.id)) {
        items.insert(index.clamp(0, items.length), item);
      }
      Get.snackbar('Watch Later', 'Could not remove it. Please try again.');
      return false;
    }, (_) => true);
  }
}

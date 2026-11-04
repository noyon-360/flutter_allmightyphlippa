import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/common/widgets/tv_focus_wrapper.dart';
import '../../../core/config/app_palette.dart';
import '../../../core/constants/app_colors.dart';
import '../../playlist/controllers/playlist_controller.dart';
import '../../playlist/models/playlist_model.dart';
import '../../search/controllers/search_controller.dart' as sc;
import '../../search/screens/search_screen.dart';
import '../../video/screens/video_play_screen.dart';
import '../controllers/watch_later_controller.dart';
import '../models/watch_later_item.dart';

class WatchLaterScreen extends StatefulWidget {
  const WatchLaterScreen({super.key});

  @override
  State<WatchLaterScreen> createState() => _WatchLaterScreenState();
}

class _WatchLaterScreenState extends State<WatchLaterScreen> {
  late final WatchLaterController controller;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    controller = Get.isRegistered<WatchLaterController>()
        ? (Get.find<WatchLaterController>()..load())
        : Get.put(WatchLaterController());
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      controller.load(isLoadMore: true);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    Get.delete<WatchLaterController>();
    super.dispose();
  }

  void _open(WatchLaterItem item) {
    switch (controller.actionFor(item)) {
      case WatchLaterOpenAction.play:
        _play(item);
      case WatchLaterOpenAction.otherPlaylist:
      case WatchLaterOpenAction.playlistGone:
        _showOtherPlaylistSheet(item);
    }
  }

  void _play(WatchLaterItem item) {
    final streamId = item.streamId;
    if (streamId == null) return;
    Get.to(() => _playerFor(item, streamId));
  }

  Widget _playerFor(WatchLaterItem item, int streamId) => VideoPlayScreen(
    streamId: streamId,
    type: item.serverType,
    autoPlay: !item.isSeries,
  );

  void _showOtherPlaylistSheet(WatchLaterItem item) {
    final gone = item.playlistId == null;
    final name = item.playlistName ?? 'another playlist';
    Get.bottomSheet(
      SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          decoration: BoxDecoration(
            color: context.palette.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                item.title.isEmpty ? 'Untitled' : item.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: context.palette.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                gone
                    ? 'The playlist this was saved from has been removed.'
                    : 'Saved from "$name". It may not be on the playlist you are using now.',
                style: TextStyle(color: context.palette.textSecondary),
              ),
              const SizedBox(height: 16),
              if (!gone)
                _SheetAction(
                  icon: Icons.swap_horiz,
                  label: 'Switch to "$name" and play',
                  autofocus: true,
                  onTap: () {
                    Get.back();
                    _switchAndPlay(item);
                  },
                ),
              _SheetAction(
                icon: Icons.search,
                label: 'Find it in this playlist',
                autofocus: gone,
                onTap: () {
                  Get.back();
                  _searchHere(item);
                },
              ),
              _SheetAction(
                icon: Icons.delete_outline,
                label: 'Remove from Watch Later',
                onTap: () {
                  Get.back();
                  controller.remove(item);
                },
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  Future<void> _switchAndPlay(WatchLaterItem item) async {
    final streamId = item.streamId;
    if (streamId == null) return;

    final playlistCtrl = Get.isRegistered<PlaylistController>()
        ? Get.find<PlaylistController>()
        : Get.put(PlaylistController());
    PlaylistModel? target = playlistCtrl.playlists.firstWhereOrNull(
      (p) => p.id == item.playlistId,
    );
    if (target == null) {
      await playlistCtrl.fetchPlaylists();
      target = playlistCtrl.playlists.firstWhereOrNull(
        (p) => p.id == item.playlistId,
      );
    }
    if (target == null) {
      Get.snackbar('Watch Later', "That playlist couldn't be found.");
      return;
    }
    await playlistCtrl.selectPlaylist(
      target,
      thenOpen: () => _playerFor(item, streamId),
    );
  }

  /// Providers often carry the same title under different ids, so a search
  /// by name on the current playlist is usually the quickest way to it.
  void _searchHere(WatchLaterItem item) {
    final searchCtrl = Get.find<sc.SearchingController>();
    final type = item.serverType;
    searchCtrl.onQueryChanged(item.title, type);
    searchCtrl.searchData(type: type);
    Get.to(() => SearchScreen(type: type));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.palette.background,
      appBar: AppBar(
        elevation: 0,
        leading: const BackButton(),
        title: Text(
          'Watch Later',
          style: TextStyle(
            color: context.palette.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Obx(
              () => Row(
                children: [
                  _ScopeChip(
                    label: 'This playlist',
                    selected:
                        controller.scope.value == WatchLaterScope.thisPlaylist,
                    onTap: () =>
                        controller.setScope(WatchLaterScope.thisPlaylist),
                  ),
                  const SizedBox(width: 8),
                  _ScopeChip(
                    label: 'All playlists',
                    selected: controller.scope.value == WatchLaterScope.all,
                    onTap: () => controller.setScope(WatchLaterScope.all),
                  ),
                ],
              ),
            ),
          ),
          Expanded(child: Obx(() => _buildBody(context))),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (controller.isLoading.value) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.red),
      );
    }

    final error = controller.errorMessage.value;
    if (error != null && controller.items.isEmpty) {
      return _Message(
        icon: Icons.cloud_off,
        title: "Couldn't load Watch Later",
        subtitle: error,
        actionLabel: 'Try again',
        onAction: controller.load,
      );
    }

    if (controller.items.isEmpty) {
      final thisPlaylist =
          controller.scope.value == WatchLaterScope.thisPlaylist;
      return _Message(
        icon: Icons.bookmark_border,
        title: 'Nothing saved yet',
        subtitle: thisPlaylist
            ? 'Tap "Watch Later" on a movie or series to save it here. Titles saved on your other playlists are under "All playlists".'
            : 'Tap "Watch Later" on a movie or series to save it here.',
      );
    }

    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = width >= 900 ? 4 : (width >= 600 ? 3 : 2);

    return Column(
      children: [
        Expanded(
          child: GridView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              childAspectRatio: 1.5,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: controller.items.length,
            itemBuilder: (context, index) {
              final item = controller.items[index];
              return _WatchLaterCard(
                item: item,
                onActivePlaylist:
                    controller.actionFor(item) == WatchLaterOpenAction.play,
                onTap: () => _open(item),
                onRemove: () => controller.remove(item),
              );
            },
          ),
        ),
        if (controller.isMoreLoading.value)
          const Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(color: AppColors.red),
          ),
      ],
    );
  }
}

class _WatchLaterCard extends StatelessWidget {
  const _WatchLaterCard({
    required this.item,
    required this.onActivePlaylist,
    required this.onTap,
    required this.onRemove,
  });

  final WatchLaterItem item;
  final bool onActivePlaylist;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: TvFocusWrapper(
            onTap: onTap,
            borderRadius: 12,
            child: Opacity(
              // Titles from another playlist may not play here; dim them so
              // that's visible before tapping.
              opacity: onActivePlaylist ? 1 : 0.55,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (item.thumbnail.isNotEmpty)
                      Image.network(
                        item.thumbnail,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _placeholder(),
                      )
                    else
                      _placeholder(),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.85),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 8, 36, 8),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title.isEmpty ? 'Untitled' : item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            item.isSeries ? 'Series' : 'Movie',
                            style: const TextStyle(
                              color: AppColors.primaryGray,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (!onActivePlaylist)
          Positioned(
            top: 8,
            left: 8,
            right: 40,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  item.playlistId == null
                      ? 'Playlist removed'
                      : 'From: ${item.playlistName ?? 'other playlist'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 11),
                ),
              ),
            ),
          ),
        Positioned(
          top: 4,
          right: 4,
          child: TvFocusWrapper(
            onTap: onRemove,
            borderRadius: 16,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 18),
            ),
          ),
        ),
      ],
    );
  }

  Widget _placeholder() => Container(
    color: AppColors.primaryBlack,
    alignment: Alignment.center,
    child: const Icon(Icons.movie_outlined, color: AppColors.primaryGray),
  );
}

class _ScopeChip extends StatelessWidget {
  const _ScopeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TvFocusWrapper(
      onTap: onTap,
      borderRadius: 20,
      focusColor: selected ? Colors.white : AppColors.red,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.red : context.palette.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : context.palette.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _SheetAction extends StatelessWidget {
  const _SheetAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.autofocus = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TvFocusWrapper(
        onTap: onTap,
        autofocus: autofocus,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: context.palette.textPrimary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(color: context.palette.textPrimary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: context.palette.textSecondary),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.palette.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: context.palette.textSecondary),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              TvFocusWrapper(
                onTap: onAction,
                autofocus: true,
                borderRadius: 24,
                focusColor: Colors.white,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.red,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Text(
                    actionLabel!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

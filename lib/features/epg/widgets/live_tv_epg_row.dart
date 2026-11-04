import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/common/widgets/tv_focus_wrapper.dart';
import '../services/live_tv_now_playing_cache.dart';
import 'package:flutter_almightyflippa/core/config/app_palette.dart';

/// A single Live TV channel row showing the channel logo/name plus whatever
/// is currently airing on it, fetched lazily and cached via
/// [LiveTvNowPlayingCache]. Fetching happens in [initState], so it only
/// fires for rows a `ListView.builder`/`GridView.builder` actually builds
/// (i.e. visible + near-viewport channels), not the whole category at once.
class LiveTvEpgRow extends StatefulWidget {
  final int streamId;
  final String channelName;
  final String channelLogo;
  final VoidCallback onTap;

  const LiveTvEpgRow({
    super.key,
    required this.streamId,
    required this.channelName,
    required this.channelLogo,
    required this.onTap,
  });

  @override
  State<LiveTvEpgRow> createState() => _LiveTvEpgRowState();
}

class _LiveTvEpgRowState extends State<LiveTvEpgRow> {
  @override
  void initState() {
    super.initState();
    Get.find<LiveTvNowPlayingCache>().ensureLoaded(widget.streamId);
  }

  @override
  Widget build(BuildContext context) {
    final cache = Get.find<LiveTvNowPlayingCache>();

    return TvFocusWrapper(
      onTap: widget.onTap,
      borderRadius: 12,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: context.palette.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.palette.textPrimary.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: context.palette.background,
                borderRadius: BorderRadius.circular(8),
              ),
              clipBehavior: Clip.antiAlias,
              child: widget.channelLogo.isNotEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(6),
                      child: Image.network(
                        widget.channelLogo,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.tv,
                          color: context.palette.textPrimary,
                        ),
                      ),
                    )
                  : Icon(Icons.tv, color: context.palette.textPrimary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.channelName,
                    style: TextStyle(
                      color: context.palette.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Obx(() {
                    final program = cache.peek(widget.streamId);
                    final isFetched = cache.nowPlaying.containsKey(widget.streamId);

                    if (!isFetched) {
                      return const _EpgLineShimmer();
                    }
                    if (program == null) {
                      return Text(
                        cache.hasFailed(widget.streamId)
                            ? 'Guide unavailable from provider'
                            : 'No program info',
                        style: TextStyle(
                          color: context.palette.textSecondary,
                          fontSize: 12,
                        ),
                      );
                    }
                    return Text(
                      '${program.title} • ${program.timeRange}',
                      style: TextStyle(
                        color: context.palette.textSecondary,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    );
                  }),
                ],
              ),
            ),
            Icon(
              Icons.play_circle_outline,
              color: context.palette.textPrimary,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

class _EpgLineShimmer extends StatelessWidget {
  const _EpgLineShimmer();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 11,
      decoration: BoxDecoration(
        color: context.palette.textPrimary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

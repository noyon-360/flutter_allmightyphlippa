import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/common/widgets/tv_focus_wrapper.dart';
import '../../../core/constants/app_colors.dart';
import '../screens/actor_screen.dart';
import '../services/cast_photo_service.dart';
import '../utils/cast_names.dart';
import 'actor_avatar.dart';

/// "Cast" row for a movie or series: a picture and name per actor; tapping one
/// opens [ActorScreen] with everything in the user's playlist they appear in.
/// Renders nothing when the provider gave no cast.
class CastSection extends StatefulWidget {
  /// The provider's raw cast text.
  final String? cast;

  const CastSection({super.key, required this.cast});

  @override
  State<CastSection> createState() => _CastSectionState();
}

class _CastSectionState extends State<CastSection> {
  late List<String> _names = parseCastNames(widget.cast);

  @override
  void initState() {
    super.initState();
    CastPhotoService.to.ensureLoaded(_names);
  }

  @override
  void didUpdateWidget(covariant CastSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cast != widget.cast) {
      _names = parseCastNames(widget.cast);
      CastPhotoService.to.ensureLoaded(_names);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_names.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Cast',
          style: TextStyle(
            color: AppColors.primaryWhite,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 104,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _names.length,
            separatorBuilder: (_, _) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final name = _names[index];
              return TvFocusWrapper(
                onTap: () => Get.to(() => ActorScreen(name: name)),
                borderRadius: 12,
                child: SizedBox(
                  width: 76,
                  child: Column(
                    children: [
                      ActorAvatar(name: name),
                      const SizedBox(height: 8),
                      Text(
                        name,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.primaryGray,
                          fontSize: 11,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

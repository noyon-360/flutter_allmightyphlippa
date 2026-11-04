import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../services/cast_photo_service.dart';
import '../utils/cast_names.dart';
import 'package:flutter_almightyflippa/core/config/app_palette.dart';

/// Round actor picture: the photo when the server knows one, otherwise the
/// actor's initials on a coloured disc (always the same colour for a name).
class ActorAvatar extends StatelessWidget {
  final String name;
  final double size;

  const ActorAvatar({super.key, required this.name, this.size = 64});

  static const _palette = [
    Color(0xFF7C4DFF),
    Color(0xFF00897B),
    Color(0xFFEF6C00),
    Color(0xFF3949AB),
    Color(0xFFC2185B),
    Color(0xFF546E7A),
  ];

  Color get _color => _palette[name.hashCode.abs() % _palette.length];

  Widget _initials(BuildContext context) => Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: _color.withValues(alpha: 0.35),
      shape: BoxShape.circle,
      border: Border.all(color: _color.withValues(alpha: 0.7)),
    ),
    child: Text(
      initialsOf(name),
      style: TextStyle(
        color: context.palette.textPrimary,
        fontSize: size * 0.34,
        fontWeight: FontWeight.w700,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final url = CastPhotoService.to.photos[name];
      if (url == null || url.isEmpty) return _initials(context);
      return ClipOval(
        child: Image.network(
          url,
          width: size,
          height: size,
          fit: BoxFit.cover,
          // A broken/blocked image should look like "no photo", not an error.
          errorBuilder: (_, _, _) => _initials(context),
          loadingBuilder: (context, child, progress) =>
              progress == null ? child : _initials(context),
        ),
      );
    });
  }
}

import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  final double height;
  final double? width;
  final String images;
  final double borderRadius;
  final Color? backgroundColor;
  final BoxFit fit;

  const AppLogo({
    super.key,
    this.height = 120,
    this.width = 120,
    required this.images,
    this.borderRadius = 0,
    this.backgroundColor,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    Widget image = Image.asset(images, height: height, width: width, fit: fit);

    if (borderRadius > 0) {
      image = ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: image,
      );
    }

    if (backgroundColor != null || borderRadius > 0) {
      return Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: image,
      );
    }

    return image;
  }
}

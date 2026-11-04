import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// 10-foot layout adjustments for Android TV, installed from
/// `GetMaterialApp.builder` only when `TvDevice.isTv`.
///
/// - **Overscan-safe margins**: Google's TV guidance keeps content 5% in
///   from the edges (48 x 27 dp on a 960 x 540 dp screen), since some TVs
///   crop the picture. Reported as safe-area padding, so every [SafeArea]
///   / Scaffold already in the app respects it while full-bleed backgrounds
///   and video still reach the edges.
/// - **Larger text**: the phone sizes are too small from the sofa; scales
///   on top of the user's own font-size setting.
class TvLayout extends StatelessWidget {
  final Widget child;

  const TvLayout({super.key, required this.child});

  static const EdgeInsets _overscan = EdgeInsets.symmetric(
    horizontal: 48,
    vertical: 27,
  );
  static const double _textScale = 1.2;

  static EdgeInsets _atLeast(EdgeInsets insets) => EdgeInsets.fromLTRB(
    math.max(insets.left, _overscan.left),
    math.max(insets.top, _overscan.top),
    math.max(insets.right, _overscan.right),
    math.max(insets.bottom, _overscan.bottom),
  );

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return MediaQuery(
      data: mq.copyWith(
        padding: _atLeast(mq.padding),
        viewPadding: _atLeast(mq.viewPadding),
        textScaler: TextScaler.linear(mq.textScaler.scale(_textScale)),
      ),
      child: child,
    );
  }
}

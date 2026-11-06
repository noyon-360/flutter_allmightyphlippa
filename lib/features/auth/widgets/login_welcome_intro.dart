import 'package:flutter/material.dart';
import 'package:flutter_almightyflippa/core/config/app_palette.dart';

/// Intro copy on the login page (phone and TV).
///
/// The wording is client-approved and also tells store reviewers that LABBY
/// supplies no content (users bring their own provider's playlist), so keep
/// it word for word.
class LoginWelcomeIntro extends StatelessWidget {
  const LoginWelcomeIntro({super.key, this.compact = false});

  /// Smaller type for the TV layout, where the QR panel and form share the
  /// screen below it.
  final bool compact;

  static const title = 'Welcome to LABBY TV';
  static const body =
      'To get started, create a free LABBY TV account. Once registered, you '
      'can sign in and add your IPTV provider’s playlist to start watching '
      'your content.';
  static const signInHint =
      'Already have an account? Simply sign in to continue.';

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final bodyStyle = TextStyle(
      color: palette.textSecondary,
      fontSize: compact ? 14 : 15,
      height: 1.4,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: palette.textPrimary,
            fontSize: compact ? 22 : 24,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: compact ? 8 : 12),
        Text(body, textAlign: TextAlign.center, style: bodyStyle),
        SizedBox(height: compact ? 4 : 8),
        Text(signInHint, textAlign: TextAlign.center, style: bodyStyle),
      ],
    );
  }
}

import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

class TvFocusWrapper extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double borderRadius;
  final FocusNode? focusNode;
  final bool autofocus;

  /// Border shown while focused; override it where the child is already red
  /// (e.g. a selected chip) so the focus ring stays visible.
  final Color focusColor;

  const TvFocusWrapper({
    super.key,
    required this.child,
    this.onTap,
    this.borderRadius = 8.0,
    this.focusNode,
    this.autofocus = false,
    this.focusColor = AppColors.red,
  });

  @override
  State<TvFocusWrapper> createState() => _TvFocusWrapperState();
}

class _TvFocusWrapperState extends State<TvFocusWrapper> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      // The border below is the focus indicator; skip the theme's fill.
      focusColor: Colors.transparent,
      onFocusChange: (hasFocus) {
        setState(() {
          _isFocused = hasFocus;
        });
        if (hasFocus) {
          Scrollable.ensureVisible(
            context,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            alignment: 0.5,
          );
        }
      },
      onTap: widget.onTap,
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          border: Border.all(
            color: _isFocused ? widget.focusColor : Colors.transparent,
            width: 2,
          ),
        ),
        child: widget.child,
      ),
    );
  }
}

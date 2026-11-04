import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../utils/tv_device.dart';

/// Lets a TV remote scroll a page of plain text (privacy policy, terms...).
///
/// Such pages have nothing focusable to move between, so the D-pad would do
/// nothing. On TV this takes focus and scrolls the [child]'s primary scroll
/// view with Up/Down; Up at the very top is passed on so focus can still
/// reach the app bar's back button. On phones it returns [child] unchanged.
///
/// The child's scroll view must use the primary scroll controller (the
/// default for a vertical [SingleChildScrollView] without a `controller`).
class TvKeyScroll extends StatefulWidget {
  final Widget child;

  const TvKeyScroll({super.key, required this.child});

  @override
  State<TvKeyScroll> createState() => _TvKeyScrollState();
}

class _TvKeyScrollState extends State<TvKeyScroll> {
  final ScrollController _controller = ScrollController();

  static const double _step = 160;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is KeyUpEvent || !_controller.hasClients) {
      return KeyEventResult.ignored;
    }
    final position = _controller.position;
    final double delta;
    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      delta = _step;
    } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      if (position.pixels <= position.minScrollExtent) {
        return KeyEventResult.ignored;
      }
      delta = -_step;
    } else {
      return KeyEventResult.ignored;
    }
    _controller.animateTo(
      (position.pixels + delta).clamp(
        position.minScrollExtent,
        position.maxScrollExtent,
      ),
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
    );
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    if (!TvDevice.isTv) return widget.child;
    return Focus(
      autofocus: true,
      onKeyEvent: _onKey,
      child: PrimaryScrollController(
        controller: _controller,
        child: widget.child,
      ),
    );
  }
}

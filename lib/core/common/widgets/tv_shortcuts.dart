import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// App-wide D-pad tweaks for Android TV, installed from
/// `GetMaterialApp.builder` only when `TvDevice.isTv`.
///
/// A single-line text field normally swallows Up/Down (they move the caret
/// to the start/end), and the default [DirectionalFocusIntent] skips text
/// fields — so on a remote, focus could never leave a field again. Mapping
/// Up/Down to a directional intent that does *not* ignore text fields lets
/// the remote move out of them, while Left/Right still move the caret.
///
/// This sits inside [DefaultTextEditingShortcuts] (the app builder's
/// content is nested under it), so it takes precedence over it.
///
/// Also: arrowing *onto* a text field would pop the on-screen keyboard over
/// the screen and trap the next presses in it. When the remote moves focus
/// onto a field the keyboard is hidden again; OK on the field opens it.
class TvShortcuts extends StatefulWidget {
  final Widget child;

  const TvShortcuts({super.key, required this.child});

  @override
  State<TvShortcuts> createState() => _TvShortcutsState();
}

class _TvShortcutsState extends State<TvShortcuts> {
  FocusNode? _lastFocus;
  DateTime _lastArrowAt = DateTime.fromMillisecondsSinceEpoch(0);

  static final _arrows = {
    LogicalKeyboardKey.arrowUp,
    LogicalKeyboardKey.arrowDown,
    LogicalKeyboardKey.arrowLeft,
    LogicalKeyboardKey.arrowRight,
  };

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_onKey);
    FocusManager.instance.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKey);
    FocusManager.instance.removeListener(_onFocusChanged);
    super.dispose();
  }

  static bool _isTextField(FocusNode? node) =>
      node?.context?.findAncestorStateOfType<EditableTextState>() != null;

  bool _onKey(KeyEvent event) {
    if (event is! KeyDownEvent) return false;
    if (_arrows.contains(event.logicalKey)) {
      _lastArrowAt = DateTime.now();
    } else if (event.logicalKey == LogicalKeyboardKey.select &&
        _isTextField(FocusManager.instance.primaryFocus)) {
      // OK on a field: bring up the keyboard (Flutter considers it already
      // shown after we hid it, so it won't on its own).
      SystemChannels.textInput.invokeMethod<void>('TextInput.show');
    }
    return false; // Observe only.
  }

  void _onFocusChanged() {
    final node = FocusManager.instance.primaryFocus;
    if (node == _lastFocus) return;
    _lastFocus = node;

    // Only when the remote moved focus — not for autofocus or the
    // keyboard's own "next" action, where the user is about to type.
    final byArrow =
        DateTime.now().difference(_lastArrowAt) <
        const Duration(milliseconds: 500);
    if (!byArrow || !_isTextField(node)) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.arrowUp): DirectionalFocusIntent(
          TraversalDirection.up,
          ignoreTextFields: false,
        ),
        SingleActivator(LogicalKeyboardKey.arrowDown): DirectionalFocusIntent(
          TraversalDirection.down,
          ignoreTextFields: false,
        ),
      },
      child: widget.child,
    );
  }
}

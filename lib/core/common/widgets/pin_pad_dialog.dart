import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../config/app_palette.dart';
import '../../constants/app_colors.dart';
import 'tv_focus_wrapper.dart';

/// On-screen number pad instead of the system keyboard: Android TV has no
/// usable keyboard for this, and the same pad works with touch and D-pad.
///
/// [validate] returns an error to show (the pad clears and stays open) or
/// null to accept. Resolves to the accepted PIN, null when cancelled, or
/// [pinPadForgot] when the user picks "Forgot PIN?" (shown with [showForgot]).
Future<String?> showPinPadDialog({
  required String title,
  String? subtitle,
  required String? Function(String pin) validate,
  int length = 4,
  bool showForgot = false,
}) {
  return Get.dialog<String>(
    _PinPadDialog(
      title: title,
      subtitle: subtitle,
      validate: validate,
      length: length,
      showForgot: showForgot,
    ),
  );
}

/// Not digits, so it can never be a real PIN.
const String pinPadForgot = 'forgot';

class _PinPadDialog extends StatefulWidget {
  const _PinPadDialog({
    required this.title,
    required this.subtitle,
    required this.validate,
    required this.length,
    required this.showForgot,
  });

  final String title;
  final String? subtitle;
  final String? Function(String pin) validate;
  final int length;
  final bool showForgot;

  @override
  State<_PinPadDialog> createState() => _PinPadDialogState();
}

class _PinPadDialogState extends State<_PinPadDialog> {
  String _pin = '';
  String? _error;

  static final _digitKeys = <LogicalKeyboardKey, String>{
    LogicalKeyboardKey.digit0: '0', LogicalKeyboardKey.numpad0: '0',
    LogicalKeyboardKey.digit1: '1', LogicalKeyboardKey.numpad1: '1',
    LogicalKeyboardKey.digit2: '2', LogicalKeyboardKey.numpad2: '2',
    LogicalKeyboardKey.digit3: '3', LogicalKeyboardKey.numpad3: '3',
    LogicalKeyboardKey.digit4: '4', LogicalKeyboardKey.numpad4: '4',
    LogicalKeyboardKey.digit5: '5', LogicalKeyboardKey.numpad5: '5',
    LogicalKeyboardKey.digit6: '6', LogicalKeyboardKey.numpad6: '6',
    LogicalKeyboardKey.digit7: '7', LogicalKeyboardKey.numpad7: '7',
    LogicalKeyboardKey.digit8: '8', LogicalKeyboardKey.numpad8: '8',
    LogicalKeyboardKey.digit9: '9', LogicalKeyboardKey.numpad9: '9',
  };

  void _add(String digit) {
    if (_pin.length >= widget.length) return;
    setState(() {
      _pin += digit;
      _error = null;
    });
    if (_pin.length == widget.length) _submit();
  }

  void _backspace() {
    if (_pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  void _submit() {
    final error = widget.validate(_pin);
    if (error == null) {
      Get.back(result: _pin);
    } else {
      setState(() {
        _error = error;
        _pin = '';
      });
    }
  }

  // Remotes with number keys (and phone hardware keyboards) can type the
  // PIN directly; key events bubble up here from the focused pad button.
  KeyEventResult _onKey(FocusNode _, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final digit = _digitKeys[event.logicalKey];
    if (digit != null) {
      _add(digit);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.backspace ||
        event.logicalKey == LogicalKeyboardKey.delete) {
      _backspace();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    Widget key({required Widget child, required VoidCallback onTap, bool autofocus = false}) {
      return Padding(
        padding: const EdgeInsets.all(6),
        child: TvFocusWrapper(
          autofocus: autofocus,
          borderRadius: 36,
          focusColor: p.textPrimary,
          onTap: onTap,
          child: Container(
            width: 64,
            height: 64,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: p.surfaceHigh,
              shape: BoxShape.circle,
            ),
            child: child,
          ),
        ),
      );
    }

    Widget digit(String d, {bool autofocus = false}) => key(
      autofocus: autofocus,
      onTap: () => _add(d),
      child: Text(
        d,
        style: TextStyle(
          color: p.textPrimary,
          fontSize: 24,
          fontWeight: FontWeight.w600,
        ),
      ),
    );

    return Focus(
      onKeyEvent: _onKey,
      child: Dialog(
        backgroundColor: p.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: p.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (widget.subtitle != null) ...[
                const SizedBox(height: 6),
                Text(
                  widget.subtitle!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: p.textSecondary, fontSize: 14),
                ),
              ],
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < widget.length; i++)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i < _pin.length
                            ? AppColors.red
                            : Colors.transparent,
                        border: Border.all(color: p.textSecondary, width: 1.5),
                      ),
                    ),
                ],
              ),
              SizedBox(
                height: 32,
                child: Center(
                  child: Text(
                    _error ?? '',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.red, fontSize: 13),
                  ),
                ),
              ),
              for (final row in const [
                ['1', '2', '3'],
                ['4', '5', '6'],
                ['7', '8', '9'],
              ])
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final d in row) digit(d, autofocus: d == '1'),
                  ],
                ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Cancel lives on the pad: TV remotes have no tap-outside.
                  key(
                    onTap: () => Get.back(),
                    child: Icon(Icons.close, color: p.textSecondary),
                  ),
                  digit('0'),
                  key(
                    onTap: _backspace,
                    child: Icon(Icons.backspace_outlined, color: p.textPrimary),
                  ),
                ],
              ),
              if (widget.showForgot) ...[
                const SizedBox(height: 8),
                TvFocusWrapper(
                  focusColor: p.textPrimary,
                  onTap: () => Get.back(result: pinPadForgot),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Text(
                      'Forgot PIN?',
                      style: TextStyle(color: p.textSecondary, fontSize: 14),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../config/app_palette.dart';
import '../../constants/app_colors.dart';
import 'tv_focus_wrapper.dart';

/// Asks for the account password. [verify] returns an error to show (the
/// dialog stays open) or null to accept. Resolves to true when accepted.
Future<bool> showPasswordConfirmDialog({
  required String title,
  String? message,
  required Future<String?> Function(String password) verify,
}) async {
  final ok = await Get.dialog<bool>(
    _PasswordConfirmDialog(title: title, message: message, verify: verify),
  );
  return ok ?? false;
}

class _PasswordConfirmDialog extends StatefulWidget {
  const _PasswordConfirmDialog({
    required this.title,
    required this.message,
    required this.verify,
  });

  final String title;
  final String? message;
  final Future<String?> Function(String password) verify;

  @override
  State<_PasswordConfirmDialog> createState() => _PasswordConfirmDialogState();
}

class _PasswordConfirmDialogState extends State<_PasswordConfirmDialog> {
  final _controller = TextEditingController();
  bool _obscure = true;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final password = _controller.text;
    if (password.isEmpty || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final error = await widget.verify(password);
    if (!mounted) return;
    if (error == null) {
      Get.back(result: true);
    } else {
      setState(() {
        _busy = false;
        _error = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Dialog(
      backgroundColor: p.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: TextStyle(
                color: p.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (widget.message != null) ...[
              const SizedBox(height: 8),
              Text(
                widget.message!,
                style: TextStyle(color: p.textSecondary, fontSize: 14),
              ),
            ],
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              autofocus: true,
              obscureText: _obscure,
              enabled: !_busy,
              style: TextStyle(color: p.textPrimary),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                hintText: 'Account password',
                hintStyle: TextStyle(color: p.hint),
                errorText: _error,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscure ? Icons.visibility_off : Icons.visibility,
                    color: p.textSecondary,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TvFocusWrapper(
                  focusColor: p.textPrimary,
                  onTap: _busy ? null : () => Get.back(result: false),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(color: p.textSecondary),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                TvFocusWrapper(
                  focusColor: p.textPrimary,
                  onTap: _busy ? null : _submit,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: _busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.red,
                            ),
                          )
                        : const Text(
                            'Confirm',
                            style: TextStyle(
                              color: AppColors.red,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

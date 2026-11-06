import 'package:flutter/material.dart';
import 'package:flutx_core/flutx_core.dart';
import 'package:get/get.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '/core/common/widgets/button_widgets.dart';
import '/core/config/app_palette.dart';
import '/core/constants/app_colors.dart';
import '/features/auth/controller/tv_qr_login_controller.dart';
import '/features/auth/models/tv_login_models.dart';

/// Left half of the TV login screen: QR code + short code that a signed-in
/// phone approves, so nobody has to type a password with the remote.
class TvQrLoginPanel extends StatefulWidget {
  const TvQrLoginPanel({super.key});

  @override
  State<TvQrLoginPanel> createState() => _TvQrLoginPanelState();
}

class _TvQrLoginPanelState extends State<TvQrLoginPanel> {
  late final TvQrLoginController _ctrl;
  final _newCodeFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _ctrl = Get.put(TvQrLoginController());
    // Start D-pad focus here, not on the email field: focusing a text field
    // pops the on-screen keyboard over the QR code.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _newCodeFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _newCodeFocus.dispose();
    Get.delete<TvQrLoginController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Sign in with your phone',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: palette.textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),
        Gap.h12,
        Text(
          'On your phone, open LABBY and go to\nProfile → Sign in on a TV. Scan this code or type it in.',
          textAlign: TextAlign.center,
          style: TextStyle(color: palette.textSecondary, fontSize: 15),
        ),
        Gap.h24,
        Obx(() {
          final denied = _ctrl.deniedNotice.value;
          return denied
              ? Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    'The request was declined on the phone. Here is a new code.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.red),
                  ),
                )
              : const SizedBox.shrink();
        }),
        // A minimum, not a fixed height: the TV's system font scale (1.2x on
        // some boxes) makes the code text taller. The minimum keeps the
        // button from jumping when the spinner swaps for the QR code.
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 300),
          child: Center(child: Obx(_buildBody)),
        ),
        Gap.h24,
        SecondaryButton(
          text: 'Get a new code',
          width: 220,
          focusNode: _newCodeFocus,
          onSimplePressed: () {
            _ctrl.deniedNotice.value = false;
            _ctrl.requestCode();
          },
        ),
      ],
    );
  }

  Widget _buildBody() {
    final palette = context.palette;
    switch (_ctrl.state.value) {
      case TvQrLoginState.loading:
      case TvQrLoginState.signingIn:
        return CircularProgressIndicator(color: palette.textPrimary);
      case TvQrLoginState.error:
        return Text(
          _ctrl.errorMessage.value,
          textAlign: TextAlign.center,
          style: TextStyle(color: palette.textSecondary, fontSize: 16),
        );
      case TvQrLoginState.showingCode:
        final code = _ctrl.code.value!.userCode;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Always black on white, whatever the theme: scanners need the
            // contrast and a quiet zone around the code.
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryWhite,
                borderRadius: BorderRadius.circular(12),
              ),
              child: QrImageView(
                data: TvLoginCodeFormat.qrPayload(code),
                size: 200,
                backgroundColor: AppColors.primaryWhite,
              ),
            ),
            Gap.h16,
            Text(
              TvLoginCodeFormat.display(code),
              style: TextStyle(
                color: palette.textPrimary,
                fontSize: 34,
                fontWeight: FontWeight.w700,
                letterSpacing: 4,
              ),
            ),
            Gap.h8,
            Text(
              'Waiting for your phone…',
              style: TextStyle(color: palette.textSecondary, fontSize: 14),
            ),
          ],
        );
    }
  }
}

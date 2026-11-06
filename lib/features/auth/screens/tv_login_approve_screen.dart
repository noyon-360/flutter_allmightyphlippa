import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutx_core/flutx_core.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '/core/common/widgets/button_widgets.dart';
import '/core/config/app_palette.dart';
import '/core/constants/app_colors.dart';
import '/core/extensions/input_decoration_extensions.dart';
import '/features/auth/controller/tv_login_approve_controller.dart';
import '/features/auth/models/tv_login_models.dart';

/// Profile → "Sign in on a TV": scan the QR code on the TV (or type its
/// code) and approve, so the TV signs in to this account.
class TvLoginApproveScreen extends StatefulWidget {
  const TvLoginApproveScreen({super.key});

  @override
  State<TvLoginApproveScreen> createState() => _TvLoginApproveScreenState();
}

class _TvLoginApproveScreenState extends State<TvLoginApproveScreen> {
  final _ctrl = Get.put(TvLoginApproveController());
  final _scanner = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: const [BarcodeFormat.qrCode],
  );
  final _codeField = TextEditingController();

  // The scanner keeps firing while the confirm dialog is open.
  bool _handling = false;

  @override
  void dispose() {
    _scanner.dispose();
    _codeField.dispose();
    Get.delete<TvLoginApproveController>();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_handling) return;
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null) return;
    final code = TvLoginCodeFormat.parseScanned(raw);
    if (code == null) {
      _ctrl.errorMessage.value = 'That isn\'t a LABBY TV code.';
      return;
    }
    await _confirmAndApprove(code);
  }

  Future<void> _onSubmitManual() async {
    if (_handling) return;
    final code = TvLoginCodeFormat.normalize(_codeField.text);
    if (code == null) {
      _ctrl.errorMessage.value =
          'Enter the ${TvLoginCodeFormat.length}-character code shown on your TV.';
      return;
    }
    await _confirmAndApprove(code);
  }

  Future<void> _confirmAndApprove(String code) async {
    _handling = true;
    final palette = context.palette;
    try {
      await _scanner.stop();
      // The code only proves someone saw the TV screen; the explicit tap
      // here is what stops a stranger's code from signing into this account.
      final ok = await Get.dialog<bool>(
        AlertDialog(
          backgroundColor: palette.surface,
          title: Text(
            'Sign in on your TV?',
            style: TextStyle(color: palette.textPrimary),
          ),
          content: Text(
            'Your TV will be signed in to your account.\n\n'
            'Only approve if code ${TvLoginCodeFormat.display(code)} is on a '
            'TV in front of you.',
            style: TextStyle(color: palette.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: Text(
                'Cancel',
                style: TextStyle(color: palette.textSecondary),
              ),
            ),
            TextButton(
              onPressed: () => Get.back(result: true),
              child: Text(
                'Approve',
                style: TextStyle(
                  color: palette.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
      if (ok != true) return;

      if (await _ctrl.approve(code)) {
        Get.back();
        Get.snackbar(
          'TV approved',
          'Your TV is signing in now.',
          backgroundColor: AppColors.successGreen,
          colorText: Colors.white,
        );
      }
    } finally {
      _handling = false;
      if (mounted) await _scanner.start();
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        backgroundColor: palette.background,
        foregroundColor: palette.textPrimary,
        title: const Text('Sign in on a TV'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'On your TV, open LABBY. Point your camera at the QR code on '
                'the TV screen.',
                style: TextStyle(color: palette.textSecondary, fontSize: 15),
              ),
              Gap.h16,
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: MobileScanner(
                    controller: _scanner,
                    onDetect: _onDetect,
                    errorBuilder: (context, error) => ColoredBox(
                      color: palette.surface,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            error.errorCode ==
                                    MobileScannerErrorCode.permissionDenied
                                ? 'Camera access is off. Type the code below '
                                      'instead, or allow camera access in '
                                      'Settings.'
                                : 'The camera isn\'t available. Type the code '
                                      'below instead.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: palette.textSecondary),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Gap.h24,
              Text(
                'Or type the code shown on your TV',
                style: TextStyle(
                  color: palette.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Gap.h12,
              TextField(
                controller: _codeField,
                textCapitalization: TextCapitalization.characters,
                autocorrect: false,
                enableSuggestions: false,
                // 8 characters + an optional dash.
                maxLength: TvLoginCodeFormat.length + 1,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9\-]')),
                ],
                style: TextStyle(
                  color: palette.textPrimary,
                  fontSize: 20,
                  letterSpacing: 3,
                ),
                decoration: context.primaryInputDecoration.copyWith(
                  hintText: 'XXXX-XXXX',
                  counterText: '',
                ),
                onSubmitted: (_) => _onSubmitManual(),
              ),
              Gap.h12,
              Obx(
                () => _ctrl.errorMessage.value.isEmpty
                    ? const SizedBox.shrink()
                    : Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          _ctrl.errorMessage.value,
                          style: const TextStyle(color: AppColors.red),
                        ),
                      ),
              ),
              Obx(
                () => _ctrl.isBusy.value
                    ? Center(
                        child: CircularProgressIndicator(
                          color: palette.textPrimary,
                        ),
                      )
                    : PrimaryButton(
                        text: 'Continue',
                        tag: 'tv_login_approve',
                        onSimplePressed: _onSubmitManual,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

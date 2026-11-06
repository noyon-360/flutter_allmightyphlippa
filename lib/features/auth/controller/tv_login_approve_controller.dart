import 'package:flutx_core/flutx_core.dart';
import 'package:get/get.dart';

import '/features/auth/models/tv_login_models.dart';
import '/features/auth/repo/auth_repo.dart';

/// Phone side of "sign in with your phone": approves the code a TV shows.
class TvLoginApproveController extends GetxController {
  TvLoginApproveController({AuthRepo? repo})
    : _repo = repo ?? Get.find<AuthRepo>();

  final AuthRepo _repo;

  final isBusy = false.obs;
  final errorMessage = ''.obs;

  /// Returns true once the backend accepted the approval.
  Future<bool> approve(String userCode) async {
    if (isBusy.value) return false;
    final code = TvLoginCodeFormat.normalize(userCode);
    if (code == null) {
      errorMessage.value = 'That code doesn\'t look right. Check the TV.';
      return false;
    }

    isBusy.value = true;
    errorMessage.value = '';
    try {
      final result = await _repo.approveTvLogin(userCode: code, approve: true);
      return result.fold<bool>((fail) {
        DPrint.log('TV login approve failed: ${fail.message}');
        errorMessage.value = switch (fail.statusCode) {
          404 || 410 =>
            'This code has expired or is wrong. Check the code on your TV.',
          429 => 'Too many tries. Please wait a minute and try again.',
          _ => "Couldn't sign in the TV. Please try again.",
        };
        return false;
      }, (_) => true);
    } finally {
      isBusy.value = false;
    }
  }
}

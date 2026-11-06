import 'dart:async';

import 'package:flutx_core/flutx_core.dart';
import 'package:get/get.dart';

import '/core/api/api_client.dart';
import '/core/services/auth_storage_service.dart';
import '/core/services/revenuecat_service.dart';
import '/features/auth/models/login_response_model.dart';
import '/features/auth/models/tv_login_models.dart';
import '/features/auth/repo/auth_repo.dart';
import '/features/playlist/screens/playlist_list_screen.dart';

enum TvQrLoginState { loading, showingCode, signingIn, error }

/// TV side of "sign in with your phone": gets a code, shows it, and polls
/// the backend until a signed-in phone approves it.
class TvQrLoginController extends GetxController {
  TvQrLoginController({
    AuthRepo? repo,
    Future<String> Function()? deviceId,
    Future<void> Function(LoginData data)? onSignedIn,
  }) : _repo = repo ?? Get.find<AuthRepo>(),
       _deviceId =
           deviceId ?? Get.find<AuthStorageService>().getOrCreateDeviceId,
       _onSignedIn = onSignedIn ?? _defaultSignedIn;

  final AuthRepo _repo;
  final Future<String> Function() _deviceId;
  final Future<void> Function(LoginData data) _onSignedIn;

  final state = TvQrLoginState.loading.obs;
  final code = Rxn<TvLoginCode>();
  final errorMessage = ''.obs;

  /// Set when the phone rejected the request, shown above the new code.
  final deniedNotice = false.obs;

  Timer? _pollTimer;
  DateTime? _expiresAt;
  bool _polling = false;

  // Bumped on every new code and on close, so a poll that returns after the
  // code changed (or the screen closed) is ignored.
  int _generation = 0;

  @override
  void onInit() {
    super.onInit();
    requestCode();
  }

  @override
  void onClose() {
    _generation++;
    _pollTimer?.cancel();
    super.onClose();
  }

  Future<void> requestCode() async {
    final gen = ++_generation;
    _pollTimer?.cancel();
    state.value = TvQrLoginState.loading;
    errorMessage.value = '';

    final result = await _repo.requestTvLoginCode(
      deviceId: await _deviceId(),
      deviceName: 'Android TV',
    );
    if (gen != _generation) return;

    result.fold(
      (fail) {
        DPrint.log('TV login code failed: ${fail.message}');
        errorMessage.value = fail.statusCode == 404
            ? 'Sign in with your phone is not available yet.'
            : "Couldn't get a sign-in code. Check the TV's internet connection.";
        state.value = TvQrLoginState.error;
      },
      (success) {
        final c = success.data;
        code.value = c;
        _expiresAt = DateTime.now().add(c.expiresIn);
        state.value = TvQrLoginState.showingCode;
        _pollTimer = Timer.periodic(c.interval, (_) => _poll(gen));
      },
    );
  }

  Future<void> _poll(int gen) async {
    final c = code.value;
    if (gen != _generation || c == null || _polling) return;

    // Expired locally: get a fresh code without asking the server.
    if (_expiresAt != null && DateTime.now().isAfter(_expiresAt!)) {
      await requestCode();
      return;
    }

    _polling = true;
    try {
      final result = await _repo.pollTvLogin(c.deviceCode);
      if (gen != _generation) return;

      await result.fold(
        (fail) async {
          // Unknown device code = expired or already used. Anything else
          // (no network, 5xx) is transient: keep polling.
          if (fail.statusCode == 404 || fail.statusCode == 410) {
            await requestCode();
          }
        },
        (success) async {
          final poll = success.data;
          switch (poll.status) {
            case TvLoginStatus.pending:
              break;
            case TvLoginStatus.expired:
              await requestCode();
            case TvLoginStatus.denied:
              deniedNotice.value = true;
              await requestCode();
            case TvLoginStatus.approved:
              _generation++;
              _pollTimer?.cancel();
              state.value = TvQrLoginState.signingIn;
              await _onSignedIn(poll.login!);
          }
        },
      );
    } finally {
      _polling = false;
    }
  }

  /// Same steps as [LoginController.login] after a successful password login.
  static Future<void> _defaultSignedIn(LoginData data) async {
    Get.find<ApiClient>().resetLogoutState();
    await Get.find<AuthStorageService>().storeAuthData(
      accessToken: data.accessToken,
      refreshToken: data.refreshToken,
      role: data.role,
      userId: data.user?.id ?? data.id ?? '',
    );
    final userId = data.user?.id ?? data.id;
    if (userId != null && userId.isNotEmpty) {
      Get.find<RevenueCatService>().loginUser(userId);
    }
    Get.offAll(() => const PlaylistListScreen());
  }
}

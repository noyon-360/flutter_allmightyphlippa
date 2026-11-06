import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/widgets.dart';
import 'package:flutx_core/core/debug_print.dart';
import 'package:get/get.dart';
import 'package:local_auth/local_auth.dart';

import '../api/api_client.dart';
import '../common/widgets/password_confirm_dialog.dart';
import '../common/widgets/pin_pad_dialog.dart';
import '../constants/api_constants.dart';
import '../constants/key_constants.dart';
import 'hive_storage_service.dart';
import 'secure_store_services.dart';

/// Content areas whose categories can be locked. Xtream category IDs are
/// only unique within one area, so locks are stored per area.
enum ParentalSection {
  live('Live TV', 'channels'),
  movies('Movies', 'movies'),
  series('Series', 'series');

  const ParentalSection(this.label, this.genreTag);

  final String label;

  /// Tag of the [GenreController] that holds this area's categories.
  final String genreTag;
}

enum PinCheck { ok, wrong, blocked }

/// Pure rules, kept apart from storage and UI so they can be unit tested.
class ParentalLockRules {
  static const int pinLength = 4;
  static const int maxFailures = 5;
  static const Duration cooldown = Duration(seconds: 30);

  static bool isValidPin(String pin) =>
      pin.length == pinLength && RegExp(r'^\d+$').hasMatch(pin);

  static String hashPin(String pin, String salt) =>
      sha256.convert(utf8.encode('$salt:$pin')).toString();

  static String newSalt([Random? random]) {
    final r = random ?? Random.secure();
    return base64Url.encode(List<int>.generate(16, (_) => r.nextInt(256)));
  }

  static String encodeIds(Set<String> ids) => (ids.toList()..sort()).join(',');

  static Set<String> decodeIds(String? raw) => raw == null || raw.isEmpty
      ? <String>{}
      : raw.split(',').where((id) => id.isNotEmpty).toSet();

  /// Locks only count while a PIN exists: without one nobody could unlock
  /// them. "All" (empty id) is never locked itself; its locked items are
  /// filtered out instead. [unlockedIds] are the locked categories the PIN
  /// was entered for this session.
  static bool isHidden({
    required bool hasPin,
    required Set<String> lockedIds,
    required Set<String> unlockedIds,
    required String categoryId,
  }) =>
      hasPin &&
      categoryId.isNotEmpty &&
      lockedIds.contains(categoryId) &&
      !unlockedIds.contains(categoryId);
}

/// Parental lock: a 4-digit PIN (optionally Face ID / fingerprint) guards
/// the categories a parent picks. Entering the PIN opens only the category
/// asked for, and every unlock ends when the app goes to the background.
class ParentalLockService extends GetxService with WidgetsBindingObserver {
  static ParentalLockService get to => Get.find();

  /// Safe from anywhere (incl. unit tests that never register the service).
  static bool hides(ParentalSection section, String categoryId) =>
      Get.isRegistered<ParentalLockService>() &&
      to.isHidden(section, categoryId);

  final _secure = SecureStoreServices();
  final _auth = LocalAuthentication();

  final hasPin = false.obs;
  final biometricsEnabled = false.obs;
  final biometricsAvailable = false.obs;

  /// Bumped whenever what should be hidden changes, so content lists update
  /// right away instead of on their next load. Check [lastChangeReveals]:
  /// hiding only needs a filter, revealing needs a reload.
  final changes = 0.obs;
  bool _lastChangeReveals = false;
  bool get lastChangeReveals => _lastChangeReveals;

  final Map<ParentalSection, RxSet<String>> _locked = {
    for (final s in ParentalSection.values) s: <String>{}.obs,
  };

  /// Locked categories opened with the PIN this session.
  final Map<ParentalSection, Set<String>> _unlocked = {
    for (final s in ParentalSection.values) s: <String>{},
  };

  String? _pinHash;
  String? _salt;
  int _failures = 0;
  DateTime? _blockedUntil;

  /// The biometric / device-credential prompt can briefly background the
  /// app on Android; that must not count as leaving the app.
  bool _authInProgress = false;

  Future<ParentalLockService> init() async {
    try {
      _pinHash = await _secure.retrieveData(KeyConstants.parentalPinHash);
      _salt = await _secure.retrieveData(KeyConstants.parentalPinSalt);
    } catch (e) {
      DPrint.error('ParentalLock: could not read PIN: $e');
    }
    hasPin.value = _pinHash != null && _salt != null;

    if (HiveStorageService.isInitialized) {
      try {
        final hive = HiveStorageService();
        biometricsEnabled.value =
            hive.get<bool?>(KeyConstants.parentalBiometrics) ?? false;
        for (final s in ParentalSection.values) {
          _locked[s]!.assignAll(
            ParentalLockRules.decodeIds(hive.get<String?>(_hiveKey(s))),
          );
        }
      } catch (e) {
        DPrint.error('ParentalLock: could not read settings: $e');
      }
    }

    biometricsAvailable.value = await _checkBiometrics();
    WidgetsBinding.instance.addObserver(this);
    return this;
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused && !_authInProgress) relock();
  }

  bool isHidden(ParentalSection section, String categoryId) =>
      ParentalLockRules.isHidden(
        hasPin: hasPin.value,
        lockedIds: _locked[section]!,
        unlockedIds: _unlocked[section]!,
        categoryId: categoryId,
      );

  /// Reactive: read inside `Obx` for the settings screen.
  bool isCategoryLocked(ParentalSection section, String categoryId) =>
      _locked[section]!.contains(categoryId);

  Future<void> setCategoryLocked(
    ParentalSection section,
    String categoryId,
    bool locked,
  ) async {
    final ids = _locked[section]!;
    if (locked) {
      ids.add(categoryId);
      // Locking a category opened earlier this session hides it now too.
      _unlocked[section]!.remove(categoryId);
    } else {
      ids.remove(categoryId);
    }
    _notify(reveals: !locked);
    try {
      await HiveStorageService().put(
        _hiveKey(section),
        ParentalLockRules.encodeIds(ids),
      );
    } catch (e) {
      DPrint.error('ParentalLock: could not save locked categories: $e');
    }
  }

  /// True when the category may be opened now, asking for the PIN /
  /// biometrics first if it's locked.
  Future<bool> guardCategory(ParentalSection section, String categoryId) async {
    if (!isHidden(section, categoryId)) return true;
    if (!await verifyParent(subtitle: 'This category is locked.')) return false;
    // Only this category opens; other locked ones stay hidden.
    _unlocked[section]!.add(categoryId);
    return true;
  }

  /// Asks for biometrics (if turned on), falling back to the PIN pad.
  /// Unlocks nothing by itself: opening the settings screen must not make
  /// locked content visible, or new locks wouldn't apply until a restart.
  Future<bool> verifyParent({String? subtitle}) async {
    if (!hasPin.value) return true;

    if (biometricsEnabled.value && biometricsAvailable.value) {
      if (await _authenticateBiometric()) return true;
    }

    final pin = await showPinPadDialog(
      title: 'Enter parental PIN',
      subtitle: subtitle,
      showForgot: true,
      validate: (pin) => switch (verifyPin(pin)) {
        PinCheck.ok => null,
        PinCheck.wrong => 'Wrong PIN, try again.',
        PinCheck.blocked =>
          'Too many tries. Wait ${ParentalLockRules.cooldown.inSeconds} seconds.',
      },
    );
    if (pin == null) return false;
    if (pin == pinPadForgot) return _resetWithAccountPassword();
    return true;
  }

  /// "Forgot PIN?": the account password belongs to the parent, so it's
  /// enough to remove the PIN. The parent then sets a new one.
  Future<bool> _resetWithAccountPassword() async {
    final ok = await showPasswordConfirmDialog(
      title: 'Forgot PIN?',
      message: 'Enter your LABBY account password to remove the PIN. '
          'You can set a new one in Profile → Parental Lock.',
      verify: _checkAccountPassword,
    );
    if (!ok) return false;
    await removePin();
    Get.snackbar(
      'Parental lock',
      'PIN removed. Set a new one in Profile → Parental Lock.',
      snackPosition: SnackPosition.BOTTOM,
    );
    return true;
  }

  /// Error message for the dialog, or null when the password is right.
  Future<String?> _checkAccountPassword(String password) async {
    final result = await ApiClient().post<bool>(
      endpoint: ApiConstants.user.verifyPassword,
      data: {'password': password},
      fromJsonT: (json) => json is Map && json['valid'] == true,
    );
    return result.fold(
      (fail) {
        DPrint.error('ParentalLock: verify password failed: ${fail.message}');
        return fail.statusCode == 404
            ? 'Not available yet. Please update the app later.'
            : 'Could not check the password. Check your connection.';
      },
      (success) => success.data == true ? null : 'Wrong password.',
    );
  }

  PinCheck verifyPin(String pin) {
    final blockedUntil = _blockedUntil;
    if (blockedUntil != null && DateTime.now().isBefore(blockedUntil)) {
      return PinCheck.blocked;
    }
    if (_pinHash != null &&
        _salt != null &&
        ParentalLockRules.hashPin(pin, _salt!) == _pinHash) {
      _failures = 0;
      _blockedUntil = null;
      return PinCheck.ok;
    }
    // A 4-digit PIN is easy to brute force by tapping, so slow that down.
    if (++_failures >= ParentalLockRules.maxFailures) {
      _failures = 0;
      _blockedUntil = DateTime.now().add(ParentalLockRules.cooldown);
      return PinCheck.blocked;
    }
    return PinCheck.wrong;
  }

  Future<void> setPin(String pin) async {
    assert(ParentalLockRules.isValidPin(pin));
    final salt = ParentalLockRules.newSalt();
    final hash = ParentalLockRules.hashPin(pin, salt);
    await _secure.storeData(KeyConstants.parentalPinSalt, salt);
    await _secure.storeData(KeyConstants.parentalPinHash, hash);
    _salt = salt;
    _pinHash = hash;
    hasPin.value = true;
    _notify(reveals: false);
  }

  /// Turns the lock off. Locked categories are kept, so setting a new PIN
  /// later brings the same locks back.
  Future<void> removePin() async {
    await _secure.deleteData(KeyConstants.parentalPinHash);
    await _secure.deleteData(KeyConstants.parentalPinSalt);
    _pinHash = null;
    _salt = null;
    hasPin.value = false;
    _clearUnlocked();
    _notify(reveals: true);
  }

  Future<void> setBiometricsEnabled(bool enabled) async {
    // Confirm the sensor works for this person before relying on it.
    if (enabled && !await _authenticateBiometric()) return;
    biometricsEnabled.value = enabled;
    try {
      await HiveStorageService().put(KeyConstants.parentalBiometrics, enabled);
    } catch (e) {
      DPrint.error('ParentalLock: could not save biometrics setting: $e');
    }
  }

  void relock() {
    if (_unlocked.values.every((ids) => ids.isEmpty)) return;
    _clearUnlocked();
    _notify(reveals: false);
  }

  void _clearUnlocked() {
    for (final ids in _unlocked.values) {
      ids.clear();
    }
  }

  void _notify({required bool reveals}) {
    _lastChangeReveals = reveals;
    changes.value++;
  }

  Future<bool> _checkBiometrics() async {
    try {
      return await _auth.canCheckBiometrics &&
          (await _auth.getAvailableBiometrics()).isNotEmpty;
    } catch (e) {
      // Android TV and devices without a sensor land here; PIN only.
      DPrint.log('ParentalLock: biometrics unavailable: $e');
      return false;
    }
  }

  Future<bool> _authenticateBiometric() async {
    _authInProgress = true;
    try {
      return await _auth.authenticate(
        localizedReason: 'Unlock parental lock',
        biometricOnly: true,
      );
    } catch (e) {
      DPrint.log('ParentalLock: biometric auth failed: $e');
      return false;
    } finally {
      _authInProgress = false;
    }
  }

  static String _hiveKey(ParentalSection s) =>
      '${KeyConstants.parentalLockedPrefix}${s.name}';
}

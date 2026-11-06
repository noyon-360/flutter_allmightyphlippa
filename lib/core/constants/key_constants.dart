// lib/core/network/constants/key_constants.dart

class KeyConstants {
  static const String onboardingStatus = 'onboarding_status';
  static const String accessToken = 'access_token';
  static const String refreshToken = 'refresh_token';
  static const String role = 'role';
  static const String userId = 'user_id';
  static const String isPaid = 'isPaid';
  static const String isAds = 'isAds';

  static const String email = 'email';
  static const String password = 'password';

  static const String playlistUrl = 'playlist_url';
  static const String playlistUsername = 'playlist_username';
  static const String playlistPassword = 'playlist_password';
  static const String playlistsList = 'playlists_list';
  static const String playlistData = 'playlist_data';

  static const String deviceId = 'device_id';

  static const String themeMode = 'theme_mode';

  // Parental lock: PIN hash + salt in secure storage, the rest in Hive.
  static const String parentalPinHash = 'parental_pin_hash';
  static const String parentalPinSalt = 'parental_pin_salt';
  static const String parentalBiometrics = 'parental_biometrics';
  static const String parentalLockedPrefix = 'parental_locked_';
}

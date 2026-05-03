class ApiConstants {
  /// [Base Configuration]
  static const String baseDomain = 'http://10.10.5.41:5001'; // Noyon Office
  // static const String baseDomain = 'http://192.168.0.218:5000'; // Noyon Home

  // static const String baseDomain = 'https://api.labbytv.com'; // PRODUCTION

  static const String baseUrl = '$baseDomain/api/v1';

  /// Dynamically generated WebSocket URL based on baseDomain
  static String get webSocketUrl {
    if (baseDomain.startsWith('https://')) {
      return baseDomain.replaceFirst('https://', 'wss://');
    } else if (baseDomain.startsWith('http://')) {
      return baseDomain.replaceFirst('http://', 'ws://');
    }
    // Fallback for unexpected cases (e.g., no scheme)
    return 'ws://$baseDomain';
  }

  /// [Headers]
  static Map<String, String> get defaultHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  static Map<String, String> authHeaders(String token) => {
    ...defaultHeaders,
    'Authorization': 'Bearer $token',
  };

  static Map<String, String> get multipartHeaders => {
    'Accept': 'application/json',
    // Content-Type will be set automatically for multipart
  };

  /// [Endpoint Groups
  static AuthEndpoints get auth => AuthEndpoints();
  static UserEndpoints get user => UserEndpoints();
  static PlaylistEndpoints get playlist => PlaylistEndpoints();

  static ServerEndpoints get server => ServerEndpoints();

  static VideoEndpoints get video => VideoEndpoints();

  static PaymentEndpoints get payment => PaymentEndpoints();
  static GenreEndpoints get genre => GenreEndpoints();
}

/// [Authentication Endpoints]
class AuthEndpoints {
  static const String _base = '${ApiConstants.baseUrl}/auth';

  final String login = '$_base/login';
  final String register = '$_base/register';

  // final String forgetPassSendOtp = '$_base/forget';
  // final String verifyOtp = '$_base/verify-otp';
  // final String resetPass = '$_base/reset-password';

  final String changePassword = '$_base/change-password';

  final String refreshToken = '$_base/refresh-token';

  // final String logout = '$_base/logout';
}

class UserEndpoints {
  static const String _base = '${ApiConstants.baseUrl}/user';

  final String profile = '$_base/profile';
  final String deleteAccount = '$_base/delete-account';
}

class PlaylistEndpoints {
  static const String _base = '${ApiConstants.baseUrl}/playlist';

  final String addPlaylist = '$_base/add-playlist';
  final String getPlaylist = '$_base/get-playlist';
  String deletePlaylist(String id) => '$_base/delete-playlist/$id';
}

class ServerEndpoints {
  static const String _base = '${ApiConstants.baseUrl}/server';

  final String connectTv = '$_base/connect-tv';
  final String getPlayUrl = '$_base/get-play-url';
}

class VideoEndpoints {
  static const String _base = '${ApiConstants.baseUrl}/watch-history';

  final String updateVideoStatus = '$_base/update';
  final String getWatchHistory = '$_base/history';
  final String getVideoStatus = '$_base/status';
  final String getFavorites = '$_base/favorites';
}

class PaymentEndpoints {
  static const String _base = '${ApiConstants.baseUrl}/payment';

  final String getMySubscription = '$_base/my-subscription';
  final String verifyApplePurchase = '$_base/verify-apple-purchase';
}

class GenreEndpoints {
  static const String _base = '${ApiConstants.baseUrl}/category';

  final String getCategories = _base;

  String getCategoriesByType(String id) => '$_base/$id';
}

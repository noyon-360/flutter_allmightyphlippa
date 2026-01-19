class ApiConstants {
  /// [Base Configuration]
  static const String baseDomain = 'http://10.10.5.48:5001'; // Noyon Office
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
  static MovieEndpoints get movie => MovieEndpoints();
  static GenreEndpoints get genre => GenreEndpoints();
  static SeriesEndpoints get series => SeriesEndpoints();
  static HistoryEndpoints get history => HistoryEndpoints();
  static AdsEndpoints get ads => AdsEndpoints();
  static LikeEndpoint get like => LikeEndpoint();
  static WatchListEndpoint get wishlist => WatchListEndpoint();
  static ReelsEndpoint get reels => ReelsEndpoint();
}

/// [Authentication Endpoints]
class AuthEndpoints {
  static const String _base = '${ApiConstants.baseUrl}/auth';

  final String login = '$_base/login';
  final String register = '$_base/register';

  final String forgetPassSendOtp = '$_base/forget';
  final String verifyOtp = '$_base/verify-otp';
  final String resetPass = '$_base/reset-password';

  final String changePassword = '$_base/change-password';

  final String refreshToken = '$_base/refresh-token';

  final String logout = '$_base/logout';
  final String delete = '$_base/delete';
}

class UserEndpoints {
  static const String _base = '${ApiConstants.baseUrl}/user';

  final String profile = '$_base/profile';
  final String updateProfile = '$_base/update-profile';
}

class MovieEndpoints {
  static const String _base = '${ApiConstants.baseUrl}/movies';

  final String getAllMovies = _base;
  final String getAllUpcomming = '$_base/upcoming';
}

class GenreEndpoints {
  static const String _base = '${ApiConstants.baseUrl}/genres';

  final String getAllGenre = _base;
}

class SeriesEndpoints {
  static const String _base = '${ApiConstants.baseUrl}/series';

  final String getAllSeries = _base;
}

class HistoryEndpoints {
  static const String _base = '${ApiConstants.baseUrl}/history';

  final String createHistory = _base;
  final String getHistory = _base;
}

class AdsEndpoints {
  static const String _base = '${ApiConstants.baseUrl}/ads';

  final String getAllAds = _base;
  String incrementWatchCount(adId) => '$_base/$adId/watch';
}

class LikeEndpoint {
  static const String _base = '${ApiConstants.baseUrl}/likes';

  final String toggleLike = '$_base/toggle';
  // final String getAllLikes = _base;
  final String getLikesByContent = '$_base/content';
  final String getUserLikes = '$_base/my-likes';
}

class WatchListEndpoint {
  static const String _base = '${ApiConstants.baseUrl}/wishlist';

  final String createWishlist = _base;
  final String getAllWishlist = _base;
  final String getWishlist = _base;
  String updateWishlist(String id) => '$_base/$id';
  String deleteWishlist(String id) => '$_base/$id';
}

class ReelsEndpoint {
  static const String _base = '${ApiConstants.baseUrl}/reels';

  final String getAllReels = _base;
}

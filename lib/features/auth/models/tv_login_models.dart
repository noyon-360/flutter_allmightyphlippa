import 'login_response_model.dart';

/// Short code shown on the TV and typed (or scanned) on the phone.
///
/// The alphabet drops vowels (so codes never spell words) and look-alikes
/// (0/O, 1/I/L, 5/S...), because people read it off a TV across the room.
/// It must match the backend's generator (docs/backend_tv_login.md).
class TvLoginCodeFormat {
  TvLoginCodeFormat._();

  static const alphabet = 'BCDFGHJKMNPQRTVWXZ2346789';
  static const length = 8;

  /// Scheme + host the QR code uses. The in-app scanner reads it; a phone
  /// camera can't open it until the app registers the deep link.
  static const qrPrefix = 'labbytv://tv-login?code=';

  /// Uppercases and strips spaces / dashes. Returns null unless the result
  /// is a full, valid code.
  static String? normalize(String input) {
    final code = input.toUpperCase().replaceAll(RegExp(r'[\s\-]'), '');
    if (code.length != length) return null;
    for (final ch in code.split('')) {
      if (!alphabet.contains(ch)) return null;
    }
    return code;
  }

  /// `K7PQ4XMZ` → `K7PQ-4XMZ`, easier to read on a TV.
  static String display(String code) {
    if (code.length != length) return code;
    return '${code.substring(0, 4)}-${code.substring(4)}';
  }

  static String qrPayload(String code) => '$qrPrefix$code';

  /// Accepts what the scanner reads: our `labbytv://tv-login?code=` link, or
  /// a bare code. Anything else (a random QR) gives null.
  static String? parseScanned(String raw) {
    final text = raw.trim();
    final uri = Uri.tryParse(text);
    if (uri != null && uri.scheme == 'labbytv') {
      if (uri.host != 'tv-login') return null;
      final code = uri.queryParameters['code'];
      return code == null ? null : normalize(code);
    }
    return normalize(text);
  }
}

/// `POST /auth/tv/code` response.
class TvLoginCode {
  /// Secret the TV polls with. Never shown on screen.
  final String deviceCode;
  final String userCode;
  final Duration expiresIn;
  final Duration interval;

  const TvLoginCode({
    required this.deviceCode,
    required this.userCode,
    required this.expiresIn,
    required this.interval,
  });

  factory TvLoginCode.fromJson(Map<String, dynamic> json) {
    int seconds(dynamic v, int fallback) =>
        v is num ? v.toInt() : int.tryParse('$v') ?? fallback;
    return TvLoginCode(
      deviceCode: json['deviceCode']?.toString() ?? '',
      userCode: json['userCode']?.toString() ?? '',
      expiresIn: Duration(seconds: seconds(json['expiresIn'], 600)),
      // Never poll faster than every 2 s, whatever the server says.
      interval: Duration(seconds: seconds(json['interval'], 5).clamp(2, 30)),
    );
  }
}

enum TvLoginStatus { pending, approved, denied, expired }

/// `POST /auth/tv/poll` response. [login] is set only when approved.
class TvLoginPollResult {
  final TvLoginStatus status;
  final LoginData? login;

  const TvLoginPollResult({required this.status, this.login});

  factory TvLoginPollResult.fromJson(Map<String, dynamic> json) {
    final status = switch (json['status']) {
      'approved' => TvLoginStatus.approved,
      'denied' => TvLoginStatus.denied,
      'expired' => TvLoginStatus.expired,
      _ => TvLoginStatus.pending,
    };
    // An "approved" reply without tokens can't sign the TV in; treat it as
    // pending so the next poll tries again.
    if (status == TvLoginStatus.approved) {
      final login = LoginData.fromJson(json);
      if ((login.accessToken ?? '').isEmpty) {
        return const TvLoginPollResult(status: TvLoginStatus.pending);
      }
      return TvLoginPollResult(status: status, login: login);
    }
    return TvLoginPollResult(status: status);
  }
}

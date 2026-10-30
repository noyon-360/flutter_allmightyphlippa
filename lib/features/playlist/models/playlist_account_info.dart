import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

/// Subscription state of a playlist's line, as reported by the provider's
/// `player_api.php`. Supplied by the backend alongside each playlist so the
/// list can warn about a line that has lapsed — or is about to — instead of
/// letting the user find out when playback fails with nothing to explain it.
class PlaylistAccountInfo {
  /// The provider's own wording, e.g. "Active", "Expired", "Banned".
  final String status;

  /// True when the line will no longer stream. Trusts an elapsed
  /// [expiresAt] as well as the provider's status, since some panels are
  /// slow to flip the latter.
  final bool isExpired;

  /// Null for lines that never expire.
  final DateTime? expiresAt;

  /// Whole days until [expiresAt]; negative once lapsed, null when there is
  /// no expiry.
  final int? daysRemaining;

  final bool isTrial;

  /// How many simultaneous streams the line allows, and how many are in use.
  final int? maxConnections;
  final int activeConnections;

  const PlaylistAccountInfo({
    required this.status,
    required this.isExpired,
    this.expiresAt,
    this.daysRemaining,
    this.isTrial = false,
    this.maxConnections,
    this.activeConnections = 0,
  });

  static PlaylistAccountInfo? fromJson(dynamic json) {
    if (json is! Map<String, dynamic>) return null;
    final expiresAtRaw = json['expiresAt'];
    return PlaylistAccountInfo(
      status: json['status'] as String? ?? 'Unknown',
      isExpired: json['isExpired'] as bool? ?? false,
      expiresAt: expiresAtRaw is String
          ? DateTime.tryParse(expiresAtRaw)?.toLocal()
          : null,
      daysRemaining: (json['daysRemaining'] as num?)?.toInt(),
      isTrial: json['isTrial'] as bool? ?? false,
      maxConnections: (json['maxConnections'] as num?)?.toInt(),
      activeConnections: (json['activeConnections'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'status': status,
        'isExpired': isExpired,
        'expiresAt': expiresAt?.toUtc().toIso8601String(),
        'daysRemaining': daysRemaining,
        'isTrial': isTrial,
        'maxConnections': maxConnections,
        'activeConnections': activeConnections,
      };

  /// The same line re-evaluated against the clock. Cached info was accurate
  /// when it was stored, so a line that has lapsed since then would otherwise
  /// still read as active until the network answers.
  PlaylistAccountInfo refreshed({DateTime? now}) {
    final on = expiresAt;
    if (on == null) return this;

    final at = now ?? DateTime.now();
    final days = on.difference(at).inDays;
    return PlaylistAccountInfo(
      status: status,
      isExpired: isExpired || !on.isAfter(at),
      expiresAt: on,
      daysRemaining: days,
      isTrial: isTrial,
      maxConnections: maxConnections,
      activeConnections: activeConnections,
    );
  }

  /// A line close enough to expiry to be worth flagging before it bites.
  static const int _warnWithinDays = 7;

  bool get isExpiringSoon {
    final days = daysRemaining;
    return !isExpired && days != null && days <= _warnWithinDays;
  }

  /// Red once it can no longer stream, amber while the clock is running
  /// down, green otherwise.
  Color get indicatorColor {
    if (isExpired) return AppColors.red;
    if (isExpiringSoon) return const Color(0xFFFFA000);
    return AppColors.successGreen;
  }

  /// One line for the playlist card, e.g. "Expired 24 Sep 2026",
  /// "Expires in 3 days" or "Active · no expiry".
  String get label {
    if (isExpired) {
      final on = expiresAt;
      return on == null ? 'Expired' : 'Expired ${_formatDate(on)}';
    }

    final days = daysRemaining;
    if (days == null) return '$status · no expiry';

    final prefix = isTrial ? 'Trial' : status;
    if (days == 0) return '$prefix · expires today';
    if (days == 1) return '$prefix · expires tomorrow';
    if (days <= _warnWithinDays) return '$prefix · expires in $days days';

    final on = expiresAt;
    return on == null ? '$prefix · $days days left' : '$prefix · until ${_formatDate(on)}';
  }

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  static String _formatDate(DateTime date) =>
      '${date.day} ${_months[date.month - 1]} ${date.year}';
}

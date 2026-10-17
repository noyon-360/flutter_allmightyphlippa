import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_almightyflippa/features/playlist/models/playlist_account_info.dart';

void main() {
  PlaylistAccountInfo? parse(Map<String, dynamic>? json) =>
      PlaylistAccountInfo.fromJson(json);

  Map<String, dynamic> payload({
    String status = 'Active',
    bool isExpired = false,
    String? expiresAt,
    int? daysRemaining,
    bool isTrial = false,
  }) => {
        'status': status,
        'isExpired': isExpired,
        'expiresAt': expiresAt,
        'daysRemaining': daysRemaining,
        'isTrial': isTrial,
        'maxConnections': 1,
        'activeConnections': 0,
      };

  test('the real expired line reads as expired with its date', () {
    final info = parse(payload(
      status: 'Expired',
      isExpired: true,
      expiresAt: '2026-09-24T04:41:29.000Z',
      daysRemaining: -23,
    ))!;
    expect(info.label, 'Expired 24 Sep 2026');
    expect(info.isExpired, isTrue);
    expect(info.isExpiringSoon, isFalse);
  });

  test('imminent expiry is worded in days and flagged', () {
    final info = parse(payload(daysRemaining: 3, expiresAt: '2026-10-20T00:00:00.000Z'))!;
    expect(info.label, 'Active · expires in 3 days');
    expect(info.isExpiringSoon, isTrue);
  });

  test('today and tomorrow get their own wording', () {
    expect(parse(payload(daysRemaining: 0))!.label, 'Active · expires today');
    expect(parse(payload(daysRemaining: 1))!.label, 'Active · expires tomorrow');
  });

  test('a healthy line shows its end date and is not flagged', () {
    final info = parse(payload(daysRemaining: 340, expiresAt: '2027-09-22T00:00:00.000Z'))!;
    expect(info.label, contains('Active · until'));
    expect(info.isExpiringSoon, isFalse);
    expect(info.isExpired, isFalse);
  });

  test('a line with no expiry says so instead of showing a date', () {
    expect(parse(payload(daysRemaining: null))!.label, 'Active · no expiry');
  });

  test('trial lines are labelled as trials', () {
    expect(parse(payload(isTrial: true, daysRemaining: 2))!.label,
        'Trial · expires in 2 days');
  });

  test('unknown account info yields no badge', () {
    expect(parse(null), isNull);
    expect(PlaylistAccountInfo.fromJson('nonsense'), isNull);
  });

  test('a lapsed date counts as expired even if the panel still says Active', () {
    final info = parse(payload(
      status: 'Active',
      isExpired: true,
      expiresAt: '2026-01-01T00:00:00.000Z',
      daysRemaining: -200,
    ))!;
    expect(info.isExpired, isTrue);
    expect(info.label, 'Expired 1 Jan 2026');
  });

  test('cached info survives a round trip through storage', () {
    final info = parse(payload(
      status: 'Active',
      expiresAt: '2027-09-22T00:00:00.000Z',
      daysRemaining: 340,
    ))!;
    final restored = parse(info.toJson())!;
    expect(restored.status, 'Active');
    expect(restored.expiresAt, info.expiresAt);
    expect(restored.daysRemaining, 340);
  });

  test('a cached line that has since lapsed is re-read as expired', () {
    final info = parse(payload(
      status: 'Active',
      expiresAt: '2026-10-01T00:00:00.000Z',
      daysRemaining: 5,
    ))!;
    final now = DateTime.parse('2026-10-17T00:00:00.000Z');
    final refreshed = info.refreshed(now: now);
    expect(refreshed.isExpired, isTrue);
    expect(refreshed.daysRemaining, lessThan(0));
    expect(refreshed.label, startsWith('Expired'));
  });

  test('a cached line still running counts down from today', () {
    final info = parse(payload(
      status: 'Active',
      expiresAt: '2026-10-20T00:00:00.000Z',
      daysRemaining: 30,
    ))!;
    final refreshed =
        info.refreshed(now: DateTime.parse('2026-10-17T00:00:00.000Z'));
    expect(refreshed.daysRemaining, 3);
    expect(refreshed.label, 'Active · expires in 3 days');
  });
}

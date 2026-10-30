import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_almightyflippa/core/services/revenuecat_service.dart';
import 'package:flutter_almightyflippa/features/auth/models/user_response_model.dart';
import 'package:flutter_almightyflippa/features/subscription/models/subscription_history_model.dart';

void main() {
  String iso(Duration fromNow) =>
      DateTime.now().toUtc().add(fromNow).toIso8601String();

  // Shape of the backend's user/profile response.
  UserModel user({
    String? status = 'active',
    String? plan = 'premium',
    String? expiresAt,
    bool? willRenew,
    String productId = 'month_subscription',
  }) => UserModel.fromJson({
        '_id': '6a4c824e217645bcd94c6f99',
        'subscriptionStatus': status,
        'plan': plan,
        'subscriptionProductId': productId,
        'subscriptionExpiresAt': expiresAt,
        'subscriptionStartDate': '2026-10-08T15:02:43.020Z',
        'subscriptionWillRenew': willRenew,
      });

  group('UserModel.hasActiveSubscription', () {
    test('active with a future expiry is active', () {
      expect(user(expiresAt: iso(const Duration(days: 9))).hasActiveSubscription, isTrue);
    });

    test('still "active" after the expiry passed reads as not active', () {
      // The backend's expiry job runs once a day (plus a 1-day buffer), so the
      // status can lag; the app must not show "Active" or block resubscribing.
      expect(user(expiresAt: iso(const Duration(hours: -2))).hasActiveSubscription, isFalse);
    });

    test('canceled is not active even before the expiry date', () {
      expect(
        user(status: 'canceled', expiresAt: iso(const Duration(days: 3))).hasActiveSubscription,
        isFalse,
      );
    });

    test('trialing counts as active', () {
      expect(
        user(status: 'trialing', expiresAt: iso(const Duration(days: 3))).hasActiveSubscription,
        isTrue,
      );
    });

    test('free user with no subscription is not active', () {
      expect(user(status: 'none', plan: 'free').hasActiveSubscription, isFalse);
    });
  });

  group('UserModel parsing', () {
    test('backend dates are UTC instants', () {
      final u = user(expiresAt: '2026-11-08T15:02:43.020Z');
      expect(u.subscriptionExpiresAt!.isUtc, isTrue);
      expect(u.subscriptionExpiresAt!.toUtc().day, 8);
    });

    test('a UTC evening date can be the next day locally', () {
      // 22:30 UTC on Nov 8 is Nov 9 in UTC+6 — the screens call toLocal()
      // before formatting, so users east of UTC see their own date.
      final utc = DateTime.parse('2026-11-08T22:30:00.000Z');
      final dhaka = utc.add(const Duration(hours: 6));
      expect(utc.day, 8);
      expect(dhaka.day, 9);
    });

    test('auto-renew flag is read and round-trips', () {
      final u = user(expiresAt: iso(const Duration(days: 3)), willRenew: false);
      expect(u.subscriptionWillRenew, isFalse);
      expect(u.toJson()['subscriptionWillRenew'], isFalse);
      expect(user().subscriptionWillRenew, isNull);
    });
  });

  group('RevenueCatService.baseProductId', () {
    test('strips the Google Play base plan', () {
      expect(
        RevenueCatService.baseProductId('month_subscription:monthly-base-plan'),
        'month_subscription',
      );
      expect(
        RevenueCatService.baseProductId('premium_t_yearly:premium-t-yearly'),
        RevenueCatService.yearlyProductId,
      );
    });

    test('leaves Apple product IDs and empty values alone', () {
      expect(RevenueCatService.baseProductId('premium_quarterly'), 'premium_quarterly');
      expect(RevenueCatService.baseProductId(null), '');
    });
  });

  group('SubscriptionHistoryModel', () {
    SubscriptionHistoryModel row({
      String status = 'active',
      String productId = 'month_subscription',
      String? expiresAt,
    }) => SubscriptionHistoryModel.fromJson({
          'platform': 'google',
          'productId': productId,
          'status': status,
          'startDate': '2026-09-08T15:02:43.020Z',
          'expiresAt': expiresAt,
        });

    test('an "active" row whose period ended shows as expired', () {
      final r = row(expiresAt: iso(const Duration(days: -22)));
      expect(r.effectiveStatus, 'expired');
      expect(r.isActive, isFalse);
    });

    test('the current period stays active', () {
      final r = row(expiresAt: iso(const Duration(days: 9)));
      expect(r.effectiveStatus, 'active');
      expect(r.isActive, isTrue);
    });

    test('refunded and canceled keep their status', () {
      expect(row(status: 'refunded').effectiveStatus, 'refunded');
      expect(row(status: 'canceled').effectiveStatus, 'canceled');
    });

    test('plan label works for Android base-plan IDs', () {
      expect(row(productId: 'month_subscription:monthly-base-plan').planLabel, 'Monthly');
      expect(row(productId: 'premium_quarterly:premium-quarterly').planLabel, 'Quarterly');
      expect(row(productId: 'premium_t_yearly').planLabel, 'Yearly');
    });
  });
}

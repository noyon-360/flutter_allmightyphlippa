import 'package:flutter_almightyflippa/core/common/widgets/premium_upsell_dialog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  String? pip({required bool premium, bool trial = false, String? offer}) =>
      PremiumUpsell.message(
        feature: 'Picture-in-Picture',
        trialIncluded: true,
        isPremium: premium,
        isFreeTrial: trial,
        trialLabel: offer,
      );

  String? parental({required bool premium, bool trial = false, String? offer}) =>
      PremiumUpsell.message(
        feature: 'Parental lock',
        trialIncluded: false,
        isPremium: premium,
        isFreeTrial: trial,
        trialLabel: offer,
      );

  group('Picture-in-Picture (Premium, free trial included)', () {
    test('open for paid and trial users', () {
      expect(pip(premium: true), isNull);
      expect(pip(premium: true, trial: true), isNull);
    });

    test('free user is offered the trial when one is available', () {
      expect(
        pip(premium: false, offer: '7-day free trial'),
        'Picture-in-Picture is a Premium feature. Start your 7-day free trial to try it free.',
      );
      expect(pip(premium: false), contains('Subscribe to unlock it'));
    });
  });

  group('Parental lock (paid Premium only)', () {
    test('open for paid users', () {
      expect(parental(premium: true), isNull);
    });

    test('closed during the free trial, with an explanation', () {
      final msg = parental(premium: true, trial: true);
      expect(msg, isNotNull);
      expect(msg, contains('isn\'t part of the free trial'));
    });

    test('free user is not promised it through the trial', () {
      expect(
        parental(premium: false, offer: '7-day free trial'),
        contains('not included in the free trial'),
      );
      expect(parental(premium: false), contains('Subscribe to unlock it'));
    });
  });
}

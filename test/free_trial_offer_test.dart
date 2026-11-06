import 'package:flutter_almightyflippa/features/auth/models/user_response_model.dart';
import 'package:flutter_almightyflippa/features/subscription/models/free_trial_offer.dart';
import 'package:flutter_almightyflippa/features/subscription/models/subscription_history_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

void main() {
  const monthly = 'month_subscription';

  PricingPhase phase(PeriodUnit unit, int value, {int amountMicros = 0, int? cycles = 1}) =>
      PricingPhase(
        Period(unit, value, 'P$value${unit.name[0].toUpperCase()}'),
        RecurrenceMode.finiteRecurring,
        cycles,
        Price(amountMicros == 0 ? 'Free' : '\$4.99', amountMicros, 'USD'),
        null,
      );

  // Google Play: RevenueCat's defaultOption is the free-trial offer only when
  // Play returned it, i.e. the user is eligible.
  StoreProduct android({PricingPhase? freePhase}) => StoreProduct(
    '$monthly:monthly-base-plan',
    'Premium',
    'Monthly',
    4.99,
    '\$4.99',
    'USD',
    defaultOption: SubscriptionOption(
      freePhase == null ? 'monthly-base-plan' : 'monthly-base-plan:free-trial',
      '$monthly:monthly-base-plan',
      monthly,
      [?freePhase, phase(PeriodUnit.month, 1, amountMicros: 4990000, cycles: null)],
      const [],
      freePhase == null,
      const Period(PeriodUnit.month, 1, 'P1M'),
      false,
      phase(PeriodUnit.month, 1, amountMicros: 4990000, cycles: null),
      freePhase,
      null,
      null,
      null,
    ),
  );

  StoreProduct ios({IntroductoryPrice? intro}) => StoreProduct(
    monthly,
    'Premium',
    'Monthly',
    4.99,
    '\$4.99',
    'USD',
    introductoryPrice: intro,
  );

  const iosFreeWeek = IntroductoryPrice(0, '\$0.00', 'P1W', 1, PeriodUnit.week, 1);

  group('FreeTrialOffer.fromProduct — Android', () {
    test('7-day free phase on the default option is a 7-day trial', () {
      final trial = FreeTrialOffer.fromProduct(
        android(freePhase: phase(PeriodUnit.day, 7)),
        isIOS: false,
      );
      expect(trial, const FreeTrialOffer(PeriodUnit.day, 7));
      expect(trial!.days, 7);
    });

    test('a one-week free phase also reads as 7 days', () {
      final trial = FreeTrialOffer.fromProduct(
        android(freePhase: phase(PeriodUnit.week, 1)),
        isIOS: false,
      );
      expect(trial!.days, 7);
      expect(trial.label, '7-day free trial');
    });

    test('no free phase (user already used the trial) means no trial', () {
      expect(FreeTrialOffer.fromProduct(android(), isIOS: false), isNull);
    });
  });

  group('FreeTrialOffer.fromProduct — iOS', () {
    test('free intro offer + eligible is a trial', () {
      final trial = FreeTrialOffer.fromProduct(
        ios(intro: iosFreeWeek),
        isIOS: true,
        iosEligibility: IntroEligibilityStatus.introEligibilityStatusEligible,
      );
      expect(trial!.days, 7);
    });

    test('ineligible or unknown eligibility is not advertised', () {
      for (final status in [
        IntroEligibilityStatus.introEligibilityStatusIneligible,
        IntroEligibilityStatus.introEligibilityStatusUnknown,
        null,
      ]) {
        expect(
          FreeTrialOffer.fromProduct(ios(intro: iosFreeWeek), isIOS: true, iosEligibility: status),
          isNull,
          reason: '$status',
        );
      }
    });

    test('a paid intro price is not a free trial', () {
      const paidIntro = IntroductoryPrice(0.99, '\$0.99', 'P1M', 1, PeriodUnit.month, 1);
      expect(
        FreeTrialOffer.fromProduct(
          ios(intro: paidIntro),
          isIOS: true,
          iosEligibility: IntroEligibilityStatus.introEligibilityStatusEligible,
        ),
        isNull,
      );
    });
  });

  group('FreeTrialOffer copy', () {
    const week = FreeTrialOffer(PeriodUnit.day, 7);

    test('labels', () {
      expect(week.label, '7-day free trial');
      expect(week.buttonLabel, 'Start 7-Day Free Trial');
      expect(week.durationText, '7 days');
      expect(const FreeTrialOffer(PeriodUnit.month, 1).durationText, '1 month');
      expect(const FreeTrialOffer(PeriodUnit.month, 1).buttonLabel, 'Start 1-Month Free Trial');
      expect(const FreeTrialOffer(PeriodUnit.unknown, 0).buttonLabel, 'Start Free Trial');
    });

    test('terms state length, renewal price and how to avoid the charge', () {
      expect(
        week.termsText('\$4.99/month'),
        'Free for 7 days, then \$4.99/month. '
        'Cancel anytime before the trial ends and you won\'t be charged.',
      );
    });
  });

  group('trial status from the backend', () {
    String iso(Duration d) => DateTime.now().toUtc().add(d).toIso8601String();

    test('trialing with a future end date is an active free trial', () {
      final user = UserModel.fromJson({
        'subscriptionStatus': 'trialing',
        'plan': 'premium',
        'subscriptionExpiresAt': iso(const Duration(days: 5)),
      });
      expect(user.hasActiveSubscription, isTrue);
      expect(user.isOnFreeTrial, isTrue);
    });

    test('a paid subscription is not a trial', () {
      final user = UserModel.fromJson({
        'subscriptionStatus': 'active',
        'subscriptionExpiresAt': iso(const Duration(days: 5)),
      });
      expect(user.isOnFreeTrial, isFalse);
    });

    test('a trial whose end date passed is over', () {
      final user = UserModel.fromJson({
        'subscriptionStatus': 'trialing',
        'subscriptionExpiresAt': iso(const Duration(hours: -1)),
      });
      expect(user.isOnFreeTrial, isFalse);
    });

    test('history rows carry isTrial; older rows default to false', () {
      expect(SubscriptionHistoryModel.fromJson({'status': 'active', 'isTrial': true}).isTrial, isTrue);
      expect(SubscriptionHistoryModel.fromJson({'status': 'active'}).isTrial, isFalse);
    });
  });
}

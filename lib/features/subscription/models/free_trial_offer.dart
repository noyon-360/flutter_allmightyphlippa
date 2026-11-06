import 'package:purchases_flutter/purchases_flutter.dart';

/// A store free-trial (introductory offer) on a subscription product.
///
/// The trial itself is configured in Play Console / App Store Connect; this
/// only reads it so the paywall can say so before the user taps.
class FreeTrialOffer {
  final PeriodUnit unit;
  final int count;

  const FreeTrialOffer(this.unit, this.count);

  /// Length in days, for "7-day" style copy. Months/years are approximate,
  /// but the label below uses the store's own unit for those.
  int get days => switch (unit) {
    PeriodUnit.day => count,
    PeriodUnit.week => count * 7,
    PeriodUnit.month => count * 30,
    PeriodUnit.year => count * 365,
    PeriodUnit.unknown => 0,
  };

  /// "7-day", "14-day", "1-month". Weeks read as days ("7-day free trial"),
  /// which is how stores and users usually describe them.
  String get lengthLabel => switch (unit) {
    PeriodUnit.day || PeriodUnit.week => '$days-day',
    PeriodUnit.month => '$count-month',
    PeriodUnit.year => '$count-year',
    PeriodUnit.unknown => '',
  };

  /// "7 days", "1 month", "2 years" — for "Free for 7 days, then …".
  String get durationText {
    String plural(int n, String word) => '$n $word${n == 1 ? '' : 's'}';
    return switch (unit) {
      PeriodUnit.day || PeriodUnit.week => plural(days, 'day'),
      PeriodUnit.month => plural(count, 'month'),
      PeriodUnit.year => plural(count, 'year'),
      PeriodUnit.unknown => 'the trial period',
    };
  }

  /// The plain-language terms stores require next to a trial offer.
  /// [priceAndPeriod] is the localized renewal price, e.g. "$4.99/month".
  String termsText(String priceAndPeriod) =>
      'Free for $durationText, then $priceAndPeriod. '
      'Cancel anytime before the trial ends and you won\'t be charged.';

  /// "7-day free trial" (or plain "Free trial" if the length is unknown).
  String get label =>
      lengthLabel.isEmpty ? 'Free trial' : '$lengthLabel free trial';

  /// Title-cased for buttons: "Start 7-Day Free Trial".
  String get buttonLabel {
    if (lengthLabel.isEmpty) return 'Start Free Trial';
    final parts = lengthLabel.split('-');
    final unitWord = parts.last[0].toUpperCase() + parts.last.substring(1);
    return 'Start ${parts.first}-$unitWord Free Trial';
  }

  /// The trial on [product] this user can actually get, or null.
  ///
  /// Android: Google Play only returns the free-trial offer to users who are
  /// eligible, and RevenueCat picks it as `defaultOption`, so its free phase
  /// is the answer. iOS: the product always carries the intro offer, so
  /// eligibility has to come from `checkTrialOrIntroductoryPriceEligibility`
  /// ([iosEligibility]). Unknown counts as not eligible: promising a free
  /// trial and then charging is worse than not mentioning it (Apple's own
  /// purchase sheet still shows the trial if there is one).
  static FreeTrialOffer? fromProduct(
    StoreProduct product, {
    required bool isIOS,
    IntroEligibilityStatus? iosEligibility,
  }) {
    if (isIOS) {
      final intro = product.introductoryPrice;
      if (intro == null || intro.price != 0) return null;
      if (iosEligibility !=
          IntroEligibilityStatus.introEligibilityStatusEligible) {
        return null;
      }
      return FreeTrialOffer(
        intro.periodUnit,
        intro.periodNumberOfUnits * (intro.cycles < 1 ? 1 : intro.cycles),
      );
    }

    final period = product.defaultOption?.freePhase?.billingPeriod;
    if (period == null) return null;
    final cycles = product.defaultOption?.freePhase?.billingCycleCount ?? 1;
    return FreeTrialOffer(period.unit, period.value * (cycles < 1 ? 1 : cycles));
  }

  @override
  bool operator ==(Object other) =>
      other is FreeTrialOffer && other.unit == unit && other.count == count;

  @override
  int get hashCode => Object.hash(unit, count);
}

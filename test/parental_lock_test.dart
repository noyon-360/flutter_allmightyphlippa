import 'dart:math';

import 'package:flutter_almightyflippa/core/common/widgets/pin_pad_dialog.dart';
import 'package:flutter_almightyflippa/core/services/parental_lock_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  group('ParentalLockRules', () {
    test('only 4-digit numeric PINs are valid', () {
      expect(ParentalLockRules.isValidPin('1234'), isTrue);
      expect(ParentalLockRules.isValidPin('0000'), isTrue);
      expect(ParentalLockRules.isValidPin('123'), isFalse);
      expect(ParentalLockRules.isValidPin('12345'), isFalse);
      expect(ParentalLockRules.isValidPin('12a4'), isFalse);
      expect(ParentalLockRules.isValidPin(''), isFalse);
    });

    test('hash is stable for the same salt and differs per salt and PIN', () {
      final a = ParentalLockRules.hashPin('1234', 'salt1');
      expect(ParentalLockRules.hashPin('1234', 'salt1'), a);
      expect(ParentalLockRules.hashPin('1234', 'salt2'), isNot(a));
      expect(ParentalLockRules.hashPin('1235', 'salt1'), isNot(a));
      expect(a, isNot(contains('1234')));
    });

    test('the "Forgot PIN" result can never be a real PIN', () {
      expect(ParentalLockRules.isValidPin(pinPadForgot), isFalse);
    });

    test('new salts are random', () {
      final r = Random(1);
      expect(
        ParentalLockRules.newSalt(r),
        isNot(ParentalLockRules.newSalt(r)),
      );
    });

    test('locked ids round-trip through storage encoding', () {
      final ids = {'12', '3', '7'};
      final raw = ParentalLockRules.encodeIds(ids);
      expect(raw, '12,3,7');
      expect(ParentalLockRules.decodeIds(raw), ids);
      expect(ParentalLockRules.decodeIds(null), isEmpty);
      expect(ParentalLockRules.decodeIds(''), isEmpty);
      expect(ParentalLockRules.decodeIds('5,,6'), {'5', '6'});
    });

    group('isHidden', () {
      bool hidden({
        bool hasPin = true,
        Set<String> unlockedIds = const {},
        String id = '5',
      }) => ParentalLockRules.isHidden(
        hasPin: hasPin,
        lockedIds: {'5', '9'},
        unlockedIds: unlockedIds,
        categoryId: id,
      );

      test('locked category is hidden while locked', () {
        expect(hidden(), isTrue);
      });

      test('other categories are not hidden', () {
        expect(hidden(id: '6'), isFalse);
      });

      test('"All" (empty id) is never hidden itself', () {
        expect(hidden(id: ''), isFalse);
      });

      test('unlocking one category leaves the others locked', () {
        expect(hidden(unlockedIds: {'5'}), isFalse);
        expect(hidden(unlockedIds: {'5'}, id: '9'), isTrue);
      });

      test('locks without a PIN are ignored', () {
        expect(hidden(hasPin: false), isFalse);
      });
    });
  });

  test('hides() is false when the service is not registered', () {
    Get.reset();
    expect(ParentalLockService.hides(ParentalSection.movies, '5'), isFalse);
  });
}

import 'package:flutter_almightyflippa/features/video/widgets/tv_vod_controls.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatPlaybackTime', () {
    test('under an hour is mm:ss', () {
      expect(formatPlaybackTime(Duration.zero), '00:00');
      expect(formatPlaybackTime(const Duration(seconds: 22)), '00:22');
      expect(
        formatPlaybackTime(const Duration(minutes: 56, seconds: 19)),
        '56:19',
      );
    });

    test('an hour or more is h:mm:ss', () {
      expect(
        formatPlaybackTime(const Duration(hours: 1, minutes: 2, seconds: 3)),
        '1:02:03',
      );
      expect(formatPlaybackTime(const Duration(hours: 2)), '2:00:00');
    });

    test('negative clamps to zero', () {
      expect(formatPlaybackTime(const Duration(seconds: -5)), '00:00');
    });
  });
}

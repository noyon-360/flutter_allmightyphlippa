import 'package:flutter_almightyflippa/features/epg/models/epg_program_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final program = EpgProgramModel(
    id: '1',
    title: 'News',
    description: '',
    startTime: DateTime(2026, 10, 30, 20),
    endTime: DateTime(2026, 10, 30, 21),
    isNowPlaying: false,
  );

  test('is airing from its start up to, but not including, its end', () {
    expect(program.isAiringAt(DateTime(2026, 10, 30, 19, 59)), isFalse);
    expect(program.isAiringAt(DateTime(2026, 10, 30, 20)), isTrue);
    expect(program.isAiringAt(DateTime(2026, 10, 30, 20, 59)), isTrue);
    expect(program.isAiringAt(DateTime(2026, 10, 30, 21)), isFalse);
  });

  test('measures progress in seconds through the program', () {
    expect(program.durationSeconds, 3600);
    expect(program.elapsedSecondsAt(DateTime(2026, 10, 30, 20, 15)), 900);
  });
}

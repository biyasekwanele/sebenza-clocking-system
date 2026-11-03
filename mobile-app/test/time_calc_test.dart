import 'package:flutter_test/flutter_test.dart';
import 'package:sebenza_clocking/core/time_calc.dart';

void main() {
  test('workedHours deducts break', () {
    final in_ = DateTime.utc(2026, 9, 20, 4, 0);
    final out = DateTime.utc(2026, 9, 20, 16, 0);
    expect(TimeCalc.workedHours(in_, out, 30), 11.5);
  });

  test('workedHours clamps at zero', () {
    final in_ = DateTime.utc(2026, 9, 20, 16, 0);
    final out = DateTime.utc(2026, 9, 20, 4, 0);
    expect(TimeCalc.workedHours(in_, out, 0), 0);
  });

  test('isLateSast uses 06:00 SAST with 5-minute grace', () {
    expect(TimeCalc.isLateSast(DateTime.utc(2026, 9, 21, 4, 5)), false);
    expect(TimeCalc.isLateSast(DateTime.utc(2026, 9, 21, 4, 6)), true);
    expect(TimeCalc.isLateSast(DateTime.utc(2026, 9, 21, 5, 15)), true);
  });

  test('formatHours', () {
    expect(TimeCalc.formatHours(8.4), '8h 24m');
    expect(TimeCalc.formatHours(0.75), '0h 45m');
    expect(TimeCalc.formatHours(-1), '0h 00m');
  });
}

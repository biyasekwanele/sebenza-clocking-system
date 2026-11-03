import 'package:flutter_test/flutter_test.dart';
import 'package:sebenza_clocking/core/payslip_calc.dart';

void main() {
  test('weekdaysInMonth: September 2026 has 22 weekdays (22/22 shifts)', () {
    expect(PayslipCalc.weekdaysInMonth(2026, 9), 22);
  });
  test('lateMinutesFor uses 06:00 SAST with 5-minute grace', () {
    expect(PayslipCalc.lateMinutesFor(DateTime.utc(2026, 9, 21, 4, 4)), 0);
    expect(PayslipCalc.lateMinutesFor(DateTime.utc(2026, 9, 21, 4, 6)), 1);
    expect(PayslipCalc.lateMinutesFor(DateTime.utc(2026, 9, 21, 5, 52)), 107);
  });
  test('payableHours: worked - late + OT, never negative', () {
    expect(PayslipCalc.payableHours(261.32, 1.87, 0), closeTo(259.45, 0.001));
    expect(PayslipCalc.payableHours(1.0, 2.0, 0), 0);
  });
  test('formatRand: South African space grouping', () {
    expect(PayslipCalc.formatRand(33728.50), 'R 33 728.50');
    expect(PayslipCalc.formatRand(130), 'R 130.00');
  });
  test('figma payslip cross-check: (261h19m - 1h52m) x R130 ≈ R33 728.50', () {
    const worked = 261 + 19 / 60.0;
    const late = 1 + 52 / 60.0;
    final pay = PayslipCalc.payableHours(worked, late, 0) * 130.0;
    expect(pay, closeTo(33728.50, 0.51));
  });
}
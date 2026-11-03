/// Pure payslip calculations (unit-tested). Mirrors the Figma payslip:
/// payable = (worked - late + approved OT) x hourly rate.
class PayslipCalc {
  static const graceMinutes = 5;

  /// Weekday (Mon-Fri) count of a month — the expected number of shifts.
  static int weekdaysInMonth(int year, int month) {
    final lastDay = DateTime(year, month + 1, 0).day;
    var count = 0;
    for (var d = 1; d <= lastDay; d++) {
      if (DateTime(year, month, d).weekday <= 5) count++;
    }
    return count;
  }

  /// Late minutes for a clock-in beyond the 06:00 SAST start (+5 min grace).
  static int lateMinutesFor(DateTime clockInUtc) {

    final clockUtc = clockInUtc.toUtc();
    final dueUtc = DateTime.utc(clockUtc.year, clockUtc.month, clockUtc.day, 4, 0).add(const Duration(minutes: graceMinutes));
    if (!clockUtc.isAfter(dueUtc)) return 0;
    return clockUtc.difference(dueUtc).inMinutes;
  }

  static double payableHours(double worked, double lateHours, double otHours) {
    final v = worked - lateHours + otHours;
    return v < 0 ? 0 : v;
  }

  /// "R 33 728.50" — South African-style space grouping.
  static String formatRand(double value) {
    final fixed = value.toStringAsFixed(2);
    final parts = fixed.split('.');
    final intPart = parts[0];
    final buf = StringBuffer();
    for (var i = 0; i < intPart.length; i++) {
      if (i > 0 && (intPart.length - i) % 3 == 0) buf.write(' ');
      buf.write(intPart[i]);
    }
    return 'R $buf.${parts[1]}';
  }
}

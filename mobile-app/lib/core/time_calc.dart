/// Pure calculations mirroring web/SebenzaClocking.Core (unit-tested).
class TimeCalc {
  static double workedHours(DateTime clockIn, DateTime clockOut, int breakMinutes) {
    final net = clockOut.difference(clockIn) -
        Duration(minutes: breakMinutes < 0 ? 0 : breakMinutes);
    if (net.inSeconds <= 0) return 0;
    return (net.inSeconds / 3600.0 * 100).roundToDouble() / 100;
  }

  static bool isLateSast(DateTime clockInUtc, {int graceMinutes = 5}) {
    final clockUtc = clockInUtc.toUtc();
    final dueUtc = DateTime.utc(clockUtc.year, clockUtc.month, clockUtc.day, 4, 0).add(Duration(minutes: graceMinutes));
    return clockUtc.isAfter(dueUtc);
  }

  /// "8h 24m"
  static String formatHours(double hours) {
    if (hours < 0) hours = 0;
    final totalMinutes = (hours * 60).round();
    return '${totalMinutes ~/ 60}h ${(totalMinutes % 60).toString().padLeft(2, '0')}m';
  }

  /// "06:12:34" ticker text.
  static String hms(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.inHours)}:${two(d.inMinutes % 60)}:${two(d.inSeconds % 60)}';
  }
}

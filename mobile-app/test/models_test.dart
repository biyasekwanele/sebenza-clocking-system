import 'package:flutter_test/flutter_test.dart';
import 'package:sebenza_clocking/data/models.dart';

void main() {
  test('Attendance.fromMap parses record', () {
    final a = Attendance.fromMap({
      'id': 'a1', 'employee_id': 'e1',
      'clock_in': '2026-09-20T04:02:00+00:00',
      'clock_out': '2026-09-20T13:10:00+00:00',
      'break_minutes': 45, 'total_hours': 8.88,
      'overtime_hours': 0, 'status': 'Completed',
    });
    expect(a.isOpen, false);
    expect(a.breakMinutes, 45);
    expect(a.totalHours, closeTo(8.88, 0.001));
  });

  test('OvertimeRequest.fromMap parses status', () {
    final o = OvertimeRequest.fromMap({
      'id': 'o1', 'employee_id': 'e1', 'reason': 'Urgent coal sample analysis',
      'status': 'Pending', 'work_date': '2026-09-19',
      'created_at': '2026-09-19T16:30:00+00:00', 'hours': 1.5,
    });
    expect(o.status, 'Pending');
    expect(o.hours, closeTo(1.5, 0.001));
  });
}

import 'package:supabase_flutter/supabase_flutter.dart';
import 'models.dart';

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}

/// Service layer (MVVM). All clock writes go through security-definer RPCs so
/// the server sets the time; reads are scoped by RLS.
class Api {
  SupabaseClient get client => Supabase.instance.client;

  // ------------------------------------------------------------ auth
  Future<void> signIn(String codeOrEmail, String password) async {
    final email = await client.rpc('resolve_employee_email',
            params: {'p_code': codeOrEmail.trim()}) as String?;
    if (email == null || email.isEmpty) {
      throw ApiException('Unknown employee ID. Contact HR if this is a mistake.');
    }
    try {
      await client.auth.signInWithPassword(email: email, password: password);
    } on AuthException catch (e) {
      throw ApiException('Sign in failed: ${e.message}');
    }
  }

  Future<void> signOut() => client.auth.signOut();

  Future<Employee> currentEmployee() async {
    final row = await client.from('employees').select(
        'id, employee_code, full_name, email, role, job_title, tax_number, bank_account_masked, hourly_rate, departments(name)')
        .eq('user_id', client.auth.currentUser!.id).single();
    return Employee.fromMap(row);
  }

  // ---------------------------------------------------------- attendance
  Future<String> _employeeId() async => (await client.from('employees')
          .select('id').eq('user_id', client.auth.currentUser!.id).single())['id'];

  Future<Attendance?> today() async {
    final emp = await _employeeId();
    final localMidnight =
        DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final rows = await client.from('attendance').select()
        .eq('employee_id', emp)
        .gte('clock_in', localMidnight.toUtc().toIso8601String())
        .order('clock_in', ascending: false).limit(1);
    return rows.isEmpty ? null : Attendance.fromMap(rows.first);
  }

  Future<Attendance> clockIn() async =>
      Attendance.fromMap(await client.rpc('clock_in'));
  Future<Attendance> clockOut() async =>
      Attendance.fromMap(await client.rpc('clock_out'));
  Future<Attendance> recordBreak(int minutes) async =>
      Attendance.fromMap(await client.rpc('record_break',
          params: {'p_minutes': minutes.clamp(1, 120)}));

  /// All attendance records whose clock-in falls in the given local month.
  Future<List<Attendance>> monthAttendance(DateTime month) async {
    final emp = await _employeeId();
    final start = DateTime(month.year, month.month, 1).toUtc().toIso8601String();
    final end = DateTime(month.year, month.month + 1, 1).toUtc().toIso8601String();
    final rows = await client.from('attendance').select()
        .eq('employee_id', emp)
        .gte('clock_in', start)
        .lt('clock_in', end)
        .order('clock_in', ascending: false);
    return rows.map(Attendance.fromMap).toList();
  }

  Future<List<Attendance>> history({int offset = 0, int limit = 20}) async {
    final emp = await _employeeId();
    final rows = await client.from('attendance').select()
        .eq('employee_id', emp)
        .order('clock_in', ascending: false)
        .range(offset, offset + limit - 1);
    return rows.map(Attendance.fromMap).toList();
  }

  Future<List<Attendance>> completedRecords({int limit = 10}) async {
    final emp = await _employeeId();
    final rows = await client.from('attendance').select()
        .eq('employee_id', emp).not('clock_out', 'is', null)
        .order('clock_in', ascending: false).limit(limit);
    return rows.map(Attendance.fromMap).toList();
  }

  // ---------------------------------------------------------- overtime
  Future<List<OvertimeRequest>> myOvertime() async {
    final emp = await _employeeId();
    final rows = await client.from('overtime').select()
        .eq('employee_id', emp).order('work_date', ascending: false).limit(100);
    return rows.map(OvertimeRequest.fromMap).toList();
  }

  Future<void> submitOvertime(String attendanceId, double hours, String reason) async {
    try {
      await client.rpc('request_overtime', params: {
        'p_attendance_id': attendanceId, 'p_hours': hours, 'p_reason': reason,
      });
    } on PostgrestException catch (e) { throw ApiException(e.message); }
  }

  // --------------------------------------------------------- corrections
  Future<List<Correction>> myCorrections() async {
    final emp = await _employeeId();
    final rows = await client.from('attendance_corrections').select()
        .eq('employee_id', emp).order('created_at', ascending: false).limit(50);
    return rows.map(Correction.fromMap).toList();
  }

  Future<void> requestCorrection(String attendanceId, String field,
      String newValue, String reason) async {
    try {
      await client.rpc('request_correction', params: {
        'p_attendance_id': attendanceId, 'p_field': field,
        'p_new_value': newValue, 'p_reason': reason,
      });
    } on PostgrestException catch (e) { throw ApiException(e.message); }
  }
}

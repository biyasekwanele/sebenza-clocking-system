class Employee {
  final String id, employeeCode, fullName, email, role;
  final String? departmentName, jobTitle, taxNumber, bankAccountMasked;
  final double? hourlyRate;
  const Employee({required this.id, required this.employeeCode, required this.fullName,
      required this.email, required this.role, this.departmentName,
      this.jobTitle, this.taxNumber, this.bankAccountMasked, this.hourlyRate});
  factory Employee.fromMap(Map<String, dynamic> m) => Employee(
      id: m['id'], employeeCode: m['employee_code'], fullName: m['full_name'],
      email: m['email'], role: m['role'],
      departmentName: m['departments']?['name'],
      jobTitle: m['job_title'], taxNumber: m['tax_number'],
      bankAccountMasked: m['bank_account_masked'],
      hourlyRate: (m['hourly_rate'] as num?)?.toDouble());
}

class Attendance {
  final String id, employeeId, status;
  final DateTime clockIn;
  final DateTime? clockOut;
  final int breakMinutes;
  final double? totalHours;
  final double overtimeHours;
  const Attendance({required this.id, required this.employeeId, required this.clockIn,
      this.clockOut, this.breakMinutes = 0, this.totalHours,
      this.overtimeHours = 0, this.status = 'Open'});

  factory Attendance.fromMap(Map<String, dynamic> m) => Attendance(
      id: m['id'], employeeId: m['employee_id'],
      clockIn: DateTime.parse(m['clock_in']),
      clockOut: m['clock_out'] == null ? null : DateTime.parse(m['clock_out']),
      breakMinutes: (m['break_minutes'] as num?)?.toInt() ?? 0,
      totalHours: (m['total_hours'] as num?)?.toDouble(),
      overtimeHours: (m['overtime_hours'] as num?)?.toDouble() ?? 0,
      status: m['status'] ?? 'Open');

  bool get isOpen => clockOut == null;
}

class OvertimeRequest {
  final String id, employeeId, reason, status;
  final DateTime workDate, createdAt;
  final double hours;
  const OvertimeRequest({required this.id, required this.employeeId, required this.reason,
      required this.status, required this.workDate, required this.createdAt, required this.hours});
  factory OvertimeRequest.fromMap(Map<String, dynamic> m) => OvertimeRequest(
      id: m['id'], employeeId: m['employee_id'], reason: m['reason'], status: m['status'],
      workDate: DateTime.parse(m['work_date']),
      createdAt: DateTime.parse(m['created_at']),
      hours: (m['hours'] as num).toDouble());
}

class Correction {
  final String id, attendanceId, employeeId, field, newValue, reason, status;
  final String? oldValue;
  final DateTime createdAt;
  const Correction({required this.id, required this.attendanceId, required this.employeeId,
      required this.field, required this.newValue, required this.reason, required this.status,
      required this.createdAt, this.oldValue});
  factory Correction.fromMap(Map<String, dynamic> m) => Correction(
      id: m['id'], attendanceId: m['attendance_id'], employeeId: m['employee_id'],
      field: m['field'], newValue: m['new_value'], reason: m['reason'], status: m['status'],
      createdAt: DateTime.parse(m['created_at']), oldValue: m['old_value']);
}

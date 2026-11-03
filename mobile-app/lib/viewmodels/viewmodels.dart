import 'dart:async';
import 'package:flutter/foundation.dart';
import '../core/payslip_calc.dart';
import '../data/api.dart';
import '../data/models.dart';

class BaseVm extends ChangeNotifier {
  bool busy = false;
  String? error;
  Future<T> guard<T>(Future<T> Function() fn) async {
    busy = true; error = null; notifyListeners();
    try { return await fn(); }
    on ApiException catch (e) { error = e.message; rethrow; }
    catch (_) { error = 'Network error. Check your connection and try again.'; rethrow; }
    finally { busy = false; notifyListeners(); }
  }
}

class AuthVm extends BaseVm {
  final Api api;
  Employee? employee;
  AuthVm(this.api);

  Future<bool> signIn(String code, String password) async {
    await guard(() => api.signIn(code, password));
    if (error == null) employee = await api.currentEmployee();
    notifyListeners();
    return error == null;
  }

  Future<void> loadProfile() async { employee = await guard(() => api.currentEmployee()); }

  Future<void> signOut() async {
    try { await api.signOut(); } catch (_) { /* offline: clear locally anyway */ }
    employee = null;
    notifyListeners();
  }
}

class ClockVm extends BaseVm {
  final Api api;
  Attendance? today;
  DateTime? _breakStart;
  Timer? _ticker;
  Duration elapsed = Duration.zero;
  DateTime now = DateTime.now();

  ClockVm(this.api) {
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      now = DateTime.now();
      if (today != null && today!.isOpen) {
        var mins = today!.breakMinutes;
        if (_breakStart != null) mins += now.difference(_breakStart!).inMinutes;
        elapsed = now.difference(today!.clockIn) - Duration(minutes: mins);
        if (elapsed.isNegative) elapsed = Duration.zero;
      }
      notifyListeners();
    });
  }

  bool get onBreak => _breakStart != null;

  Future<void> refresh() async {
    today = await guard(() => api.today());
    _breakStart = null;
    notifyListeners();
  }

  Future<void> clockIn() async {
    if (busy) return; // prevent duplicate submissions
    today = await guard(() => api.clockIn());
    notifyListeners();
  }

  Future<void> clockOut() async {
    if (busy) return;
    today = await guard(() => api.clockOut());
    _breakStart = null;
    notifyListeners();
  }

  Future<void> startBreak() async {
    if (busy || today == null || !today!.isOpen || _breakStart != null) return;
    _breakStart = DateTime.now();
    notifyListeners();
  }

  Future<void> endBreak() async {
    if (_breakStart == null || busy) return;
    final minutes = DateTime.now().difference(_breakStart!).inMinutes.clamp(1, 120);
    _breakStart = null;
    notifyListeners();
    try {
      today = await guard(() => api.recordBreak(minutes));
    } catch (_) {
      // Server call failed: re-sync from the server instead of trusting local state.
      today = await guard(() => api.today());
    }
    notifyListeners();
  }

  @override
  void dispose() { _ticker?.cancel(); super.dispose(); }
}

class HistoryVm extends BaseVm {
  final Api api;
  List<Attendance> records = [];
  bool loadingMore = false;
  HistoryVm(this.api);

  Future<void> load() async {
    records = await guard(() => api.history(limit: 20));
    notifyListeners();
  }

  Future<void> loadMore() async {
    if (loadingMore) return;
    loadingMore = true; notifyListeners();
    records += await api.history(offset: records.length, limit: 20);
    loadingMore = false; notifyListeners();
  }
}

class OvertimeVm extends BaseVm {
  final Api api;
  List<OvertimeRequest> requests = [];
  List<Attendance> completed = [];
  OvertimeVm(this.api);

  Future<void> load() async {
    requests = await guard(() => api.myOvertime());
    notifyListeners();
  }

  Future<void> loadTargets() async {
    completed = await guard(() => api.completedRecords());
    notifyListeners();
  }

  Future<bool> submit(String attendanceId, double hours, String reason) async {
    await guard(() => api.submitOvertime(attendanceId, hours, reason));
    if (error == null) await load();
    return error == null;
  }
}

class CorrectionVm extends BaseVm {
  final Api api;
  List<Correction> corrections = [];
  CorrectionVm(this.api);

  Future<void> load() async {
    corrections = await guard(() => api.myCorrections());
    notifyListeners();
  }

  Future<bool> submit(String attendanceId, String field, String newValue, String reason) async {
    await guard(() => api.requestCorrection(attendanceId, field, newValue, reason));
    if (error == null) await load();
    return error == null;
  }
}

class PayslipData {
  final double workedHours, lateHours, otHours, pay, rate;
  final int shifts, expectedShifts;
  const PayslipData(this.workedHours, this.lateHours, this.otHours, this.pay,
      this.rate, this.shifts, this.expectedShifts);
}

/// Shared by the My Payslip and Monthly Hours tabs: one month of records
/// plus the derived pay summary.
class PayslipVm extends BaseVm {
  final Api api;
  static const defaultRate = 130.0; // fallback when no rate is set on the profile

  Employee? employee;
  DateTime month;
  List<Attendance> records = [];
  PayslipData? data;

  PayslipVm(this.api)
      : month = DateTime(DateTime.now().year, DateTime.now().month);

  Future<void> load() async {
    await guard(() async {
      employee = await api.currentEmployee();
      records = await api.monthAttendance(month);
    });
    if (error != null) return;

    var worked = 0.0, ot = 0.0;
    var lateMin = 0, shifts = 0;
    for (final r in records) {
      if (r.clockOut != null && r.totalHours != null) {
        worked += r.totalHours!;
        shifts++;
      }
      lateMin += PayslipCalc.lateMinutesFor(r.clockIn);
      ot += r.overtimeHours;
    }
    final rate = (employee?.hourlyRate ?? 0) > 0
        ? employee!.hourlyRate!
        : defaultRate;
    final lateH = lateMin / 60.0;
    data = PayslipData(
      worked, lateH, ot,
      PayslipCalc.payableHours(worked, lateH, ot) * rate,
      rate, shifts,
      PayslipCalc.weekdaysInMonth(month.year, month.month),
    );
    notifyListeners();
  }

  Future<void> changeMonth(int delta) async {
    month = DateTime(month.year, month.month + delta);
    await load();
  }
}

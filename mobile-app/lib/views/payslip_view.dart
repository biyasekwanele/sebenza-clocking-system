import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../core/payslip_calc.dart';
import '../core/theme.dart';
import '../core/time_calc.dart';
import '../viewmodels/viewmodels.dart';

class PayslipView extends StatelessWidget {
  const PayslipView({super.key});

  static const _paper = Color(0xFFF5F1E6);
  static const _ink = Color(0xFF1C1E20);

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PayslipVm>();

    return Scaffold(
      appBar: AppBar(title: const Text('My Payslip')),
      body: vm.busy && vm.data == null
          ? const Center(child: CircularProgressIndicator(color: SebenzaTheme.amber))
          : ListView(padding: const EdgeInsets.all(16), children: [
              _monthNav(vm),
              const SizedBox(height: 16),
              if (vm.data == null)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('Could not load payslip data.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: SebenzaTheme.muted)))
              else if (vm.records.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text('No attendance records for ${DateFormat('MMMM yyyy').format(vm.month)}.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: SebenzaTheme.muted)))
              else _payslipCard(vm),
              const SizedBox(height: 16),
              const Text(
                'Summary for information only — Sebenza records attendance and does not process salary payments.',
                textAlign: TextAlign.center,
                style: TextStyle(color: SebenzaTheme.muted, fontSize: 11),
              ),
              if (vm.error != null)
                Padding(padding: const EdgeInsets.only(top: 12),
                  child: Text(vm.error!,
                      style: const TextStyle(color: SebenzaTheme.red))),
            ]),
    );
  }

  Widget _monthNav(PayslipVm vm) => Row(
    mainAxisAlignment: MainAxisAlignment.center, children: [
      IconButton(icon: const Icon(Icons.chevron_left, color: SebenzaTheme.text),
          onPressed: vm.busy ? null : () => vm.changeMonth(-1)),
      Text(DateFormat('MMMM yyyy').format(vm.month).toUpperCase(),
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
              letterSpacing: 1, color: SebenzaTheme.text)),
      IconButton(icon: const Icon(Icons.chevron_right, color: SebenzaTheme.text),
          onPressed: vm.busy ? null : () => vm.changeMonth(1)),
    ]);

  Widget _payslipCard(PayslipVm vm) {
    final d = vm.data!;
    final e = vm.employee;
    final payDate = DateTime(vm.month.year, vm.month.month + 1, 0);

    return Container(
      decoration: BoxDecoration(
        color: _paper,
        borderRadius: BorderRadius.circular(6),
        boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 8, offset: Offset(0, 3))],
      ),
      padding: const EdgeInsets.all(22),
      child: DefaultTextStyle(
        style: const TextStyle(color: _ink, fontFamily: 'monospace', fontSize: 13),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          // header
          Text('PAYSLIP', textAlign: TextAlign.right,
              style: TextStyle(fontSize: 10, letterSpacing: 2, color: _ink.withValues(alpha: .55))),
          Text(DateFormat('MMMM yyyy').format(vm.month).toUpperCase(),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: 1)),
          Text('PAY DATE: ${DateFormat('dd MMM yyyy').format(payDate).toUpperCase()}',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: _ink.withValues(alpha: .6))),
          const SizedBox(height: 18),
          const Divider(color: Color(0xFFB9B2A2), height: 1),
          const SizedBox(height: 14),
          // identity rows
          _pair('EMPLOYEE ID', e?.employeeCode ?? '—', 'ROLE', e?.jobTitle ?? e?.role ?? '—'),
          const SizedBox(height: 12),
          _pair('TAX NUMBER', e?.taxNumber ?? '—', 'BANK ACCOUNT', e?.bankAccountMasked ?? '—'),
          const SizedBox(height: 18),
          // stat tiles
          Row(children: [
            Expanded(child: _tile('WORKED', TimeCalc.formatHours(d.workedHours), _ink)),
            const SizedBox(width: 8),
            Expanded(child: _tile('LATE DEDUCTED', TimeCalc.formatHours(d.lateHours), const Color(0xFFB3402F))),
            const SizedBox(width: 8),
            Expanded(child: _tile('APPROVED OT', TimeCalc.formatHours(d.otHours), const Color(0xFFB97A1E))),
            const SizedBox(width: 8),
            Expanded(child: _tile('SHIFTS', '${d.shifts}/${d.expectedShifts}', _ink)),
          ]),
          const SizedBox(height: 18),
          const Divider(color: Color(0xFFB9B2A2), height: 1),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('(${PayslipCalc.formatRand(d.rate)}/h)',
                style: TextStyle(fontSize: 11, color: _ink.withValues(alpha: .6))),
            Text(PayslipCalc.formatRand(d.pay),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          ]),
        ]),
      ),
    );
  }

  Widget _pair(String k1, String v1, String k2, String v2) => Row(children: [
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(k1, style: TextStyle(fontSize: 9, letterSpacing: 1, color: _ink.withValues(alpha: .55))),
      Text(v1, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
    ])),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(k2, style: TextStyle(fontSize: 9, letterSpacing: 1, color: _ink.withValues(alpha: .55))),
      Text(v2, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
    ])),
  ]);

  Widget _tile(String label, String value, Color valueColor) => Container(
    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
    decoration: BoxDecoration(
      color: _ink.withValues(alpha: .05),
      borderRadius: BorderRadius.circular(4),
    ),
    child: Column(children: [
      FittedBox(fit: BoxFit.scaleDown, child: Text(label,
          style: TextStyle(fontSize: 8, letterSpacing: .5, color: _ink.withValues(alpha: .55)))),
      const SizedBox(height: 4),
      FittedBox(fit: BoxFit.scaleDown, child: Text(value,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: valueColor))),
    ]),
  );
}

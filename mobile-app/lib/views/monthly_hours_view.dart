import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../core/time_calc.dart';
import '../viewmodels/viewmodels.dart';

class MonthlyHoursView extends StatelessWidget {
  const MonthlyHoursView({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PayslipVm>();

    return Scaffold(
      appBar: AppBar(title: const Text('Monthly Hours')),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            IconButton(icon: const Icon(Icons.chevron_left, color: SebenzaTheme.text),
                onPressed: vm.busy ? null : () => vm.changeMonth(-1)),
            Text(DateFormat('MMMM yyyy').format(vm.month).toUpperCase(),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                    letterSpacing: 1, color: SebenzaTheme.text)),
            IconButton(icon: const Icon(Icons.chevron_right, color: SebenzaTheme.text),
                onPressed: vm.busy ? null : () => vm.changeMonth(1)),
          ]),
        ),
        const Divider(height: 1),
        Expanded(
          child: vm.busy && vm.records.isEmpty
              ? const Center(child: CircularProgressIndicator(color: SebenzaTheme.amber))
              : vm.records.isEmpty
                  ? const Center(child: Text('No attendance this month.',
                      style: TextStyle(color: SebenzaTheme.muted)))
                  : ListView.separated(
                      itemCount: vm.records.length + 1,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        if (i == vm.records.length) return _totals(vm);
                        final r = vm.records[i];
                        final late = TimeCalc.isLateSast(r.clockIn);
                        return ListTile(
                          dense: true,
                          title: Text(DateFormat('EEE dd MMM').format(r.clockIn.toLocal()),
                              style: TextStyle(
                                  color: late ? SebenzaTheme.red : SebenzaTheme.text,
                                  fontWeight: FontWeight.w600, fontSize: 14)),
                          subtitle: Text(
                            'in ${DateFormat('HH:mm').format(r.clockIn.toLocal())}'
                            '${r.clockOut == null ? ' — still clocked in' : ' – out ${DateFormat('HH:mm').format(r.clockOut!.toLocal())}'}'
                            '${r.breakMinutes > 0 ? '  · ${r.breakMinutes}m break' : ''}',
                            style: const TextStyle(fontSize: 12, color: SebenzaTheme.muted)),
                          trailing: Text(
                            r.totalHours == null ? '—' : TimeCalc.formatHours(r.totalHours!),
                            style: const TextStyle(fontWeight: FontWeight.w700)),
                        );
                      }),
        ),
      ]),
    );
  }

  Widget _totals(PayslipVm vm) {
    final d = vm.data;
    if (d == null) return const SizedBox.shrink();
    return Container(
      color: SebenzaTheme.panel2,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        _total('WORKED', TimeCalc.formatHours(d.workedHours)),
        _total('LATE', TimeCalc.formatHours(d.lateHours), SebenzaTheme.red),
        _total('OT', TimeCalc.formatHours(d.otHours), SebenzaTheme.amber),
        _total('EST. PAY', formatRand(d.pay), SebenzaTheme.green),
      ]),
    );
  }

  Widget _total(String label, String value, [Color color = SebenzaTheme.text]) => Column(children: [
    Text(value, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: color)),
    const SizedBox(height: 2),
    Text(label, style: const TextStyle(fontSize: 9, color: SebenzaTheme.muted, letterSpacing: .5)),
  ]);

  // local alias to avoid importing payslip_calc just for formatting
  static String formatRand(double v) {
    final fixed = v.toStringAsFixed(2);
    final parts = fixed.split('.');
    final intPart = parts[0];
    final buf = StringBuffer();
    for (var i = 0; i < intPart.length; i++) {
      if (i > 0 && (intPart.length - i) % 3 == 0) buf.write(' ');
      buf.write(intPart[i]);
    }
    return 'R$buf';
  }
}

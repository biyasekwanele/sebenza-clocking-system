import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../core/time_calc.dart';
import '../viewmodels/viewmodels.dart';

class ClockView extends StatelessWidget {
  const ClockView({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ClockVm>();
    final today = vm.today;
    final clockedIn = today != null && today.isOpen;

    return Scaffold(
      appBar: AppBar(title: const Text("Today's Shift")),
      body: SafeArea(child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          Card(child: ListTile(
            leading: const Icon(Icons.brightness_6_outlined, color: SebenzaTheme.amber),
            title: const Text('WORKING SHIFT',
                style: TextStyle(fontSize: 11, color: SebenzaTheme.muted)),
            subtitle: Text(
                clockedIn
                    ? 'Clocked in at ${TimeOfDay.fromDateTime(today.clockIn.toLocal()).format(context)}'
                    : 'Not clocked in',
                style: const TextStyle(fontSize: 15)),
            trailing: Icon(Icons.circle, size: 12,
                color: clockedIn
                    ? (vm.onBreak ? SebenzaTheme.blue : SebenzaTheme.green)
                    : SebenzaTheme.muted),
          )),
          const SizedBox(height: 28),
          Text(
              TimeCalc.hms(clockedIn
                  ? vm.elapsed
                  : Duration(hours: vm.now.hour, minutes: vm.now.minute, seconds: vm.now.second)),
              style: const TextStyle(fontSize: 44, fontWeight: FontWeight.w300,
                  color: SebenzaTheme.amber)),
          Text(_dateLine(vm.now),
              style: const TextStyle(color: SebenzaTheme.muted, fontSize: 12)),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
                border: Border.all(
                    color: clockedIn ? SebenzaTheme.green : SebenzaTheme.muted),
                borderRadius: BorderRadius.circular(20)),
            child: Text(
                !clockedIn
                    ? 'NOT CLOCKED IN'
                    : (vm.onBreak ? 'ON BREAK' : 'CLOCKED IN'),
                style: TextStyle(
                    color: clockedIn ? SebenzaTheme.green : SebenzaTheme.muted,
                    fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1))),
          const SizedBox(height: 24),
          if (today != null && !today.isOpen)
            _statRow(today.totalHours ?? 0, today.overtimeHours)
          else if (clockedIn) ...[
            _statRow(vm.elapsed.inSeconds / 3600.0, today.overtimeHours),
            const SizedBox(height: 12),
            SizedBox(width: double.infinity, height: 50,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: SebenzaTheme.blue),
                    foregroundColor: SebenzaTheme.blue),
                icon: Icon(vm.onBreak ? Icons.play_arrow : Icons.pause),
                label: Text(vm.onBreak ? 'END BREAK' : 'GO ON BREAK'),
                onPressed: vm.busy
                    ? null
                    : (vm.onBreak ? vm.endBreak : vm.startBreak))),
            const SizedBox(height: 12),
          ] else
            const SizedBox(height: 62),
          SizedBox(width: double.infinity, height: 54,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: clockedIn ? SebenzaTheme.red : SebenzaTheme.amber,
                foregroundColor: clockedIn ? SebenzaTheme.text : const Color(0xFF141414),
                textStyle: const TextStyle(
                    fontWeight: FontWeight.w800, letterSpacing: 1, fontSize: 15)),
              onPressed: vm.busy ? null : (clockedIn ? vm.clockOut : vm.clockIn),
              child: vm.busy
                  ? const SizedBox(width: 22, height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(clockedIn ? 'CLOCK OUT' : 'CLOCK IN'))),
          const SizedBox(height: 10),
          Text('Timestamps are captured automatically',
              style: TextStyle(color: SebenzaTheme.muted.withValues(alpha: .7), fontSize: 11)),
          if (vm.error != null)
            Padding(padding: const EdgeInsets.only(top: 12),
              child: Text(vm.error!,
                  style: const TextStyle(color: SebenzaTheme.red))),
        ]),
      )),
    );
  }

  String _dateLine(DateTime d) =>
      '${_day(d.weekday)} ${d.day.toString().padLeft(2, '0')} ${_month(d.month)} ${d.year}';
  String _day(int w) => const ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'][w - 1];
  String _month(int m) => const ['JAN','FEB','MAR','APR','MAY','JUN','JUL','AUG','SEP','OCT','NOV','DEC'][m - 1];

  Widget _statRow(double worked, double ot) => Row(children: [
    Expanded(child: _stat('WORKED', TimeCalc.formatHours(worked))),
    const SizedBox(width: 12),
    Expanded(child: _stat('OVERTIME', TimeCalc.formatHours(ot))),
  ]);

  Widget _stat(String label, String value) => Card(child: Padding(
    padding: const EdgeInsets.symmetric(vertical: 16),
    child: Column(children: [
      Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
      const SizedBox(height: 4),
      Text(label, style: const TextStyle(
          fontSize: 10, color: SebenzaTheme.muted, letterSpacing: 1)),
    ])));
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../core/time_calc.dart';
import '../data/api.dart';
import '../viewmodels/viewmodels.dart';
import 'correction_request_view.dart';

class HistoryView extends StatelessWidget {
  const HistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HistoryVm>();
    return Scaffold(
      appBar: AppBar(title: const Text('My Attendance')),
      body: vm.busy && vm.records.isEmpty
          ? const Center(child: CircularProgressIndicator(color: SebenzaTheme.amber))
          : vm.records.isEmpty
              ? const Center(child: Text('No attendance records yet.',
                  style: TextStyle(color: SebenzaTheme.muted)))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: vm.records.length + 1,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    if (i == vm.records.length) {
                      return TextButton(
                        onPressed: vm.loadingMore ? null : vm.loadMore,
                        child: Text(vm.loadingMore ? 'Loading…' : 'Load more'));
                    }
                    final r = vm.records[i];
                    final late = TimeCalc.isLateSast(r.clockIn);
                    return ListTile(
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) =>
                          ChangeNotifierProvider(
                              create: (c) => CorrectionVm(c.read<Api>()),
                              child: CorrectionRequestView(record: r)))),
                      title: Text(DateFormat('EEE dd MMM').format(r.clockIn.toLocal()),
                          style: TextStyle(
                              color: late ? SebenzaTheme.red : SebenzaTheme.text,
                              fontWeight: FontWeight.w600)),
                      subtitle: Text(
                        'IN ${DateFormat('HH:mm').format(r.clockIn.toLocal())}'
                        '${r.clockOut == null ? '' : '   OUT ${DateFormat('HH:mm').format(r.clockOut!.toLocal())}'}'
                        '${r.breakMinutes > 0 ? '   · ${r.breakMinutes}m break' : ''}',
                        style: const TextStyle(fontSize: 12, color: SebenzaTheme.muted)),
                      trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end, children: [
                        Text(r.totalHours == null ? '—' : TimeCalc.formatHours(r.totalHours!),
                            style: const TextStyle(fontWeight: FontWeight.w700)),
                        if (late)
                          const Text('LATE', style: TextStyle(
                              color: SebenzaTheme.red, fontSize: 10)),
                      ]),
                    );
                  }),
    );
  }
}

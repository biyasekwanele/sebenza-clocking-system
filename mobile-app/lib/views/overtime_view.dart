import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../core/time_calc.dart';
import '../data/api.dart';
import '../data/models.dart';
import '../viewmodels/viewmodels.dart';

class OvertimeView extends StatelessWidget {
  const OvertimeView({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<OvertimeVm>();
    return Scaffold(
      appBar: AppBar(title: const Text('Overtime')),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: SebenzaTheme.amber,
        foregroundColor: const Color(0xFF141414),
        icon: const Icon(Icons.add), label: const Text('Request'),
        onPressed: () {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) =>
              ChangeNotifierProvider(
                  create: (c) => OvertimeVm(c.read<Api>())..loadTargets(),
                  child: const OvertimeRequestView())));
        }),
      body: vm.requests.isEmpty
          ? const Center(child: Text('No overtime requests yet.',
              style: TextStyle(color: SebenzaTheme.muted)))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: vm.requests.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final o = vm.requests[i];
                final color = o.status == 'Approved' ? SebenzaTheme.green
                    : o.status == 'Rejected' ? SebenzaTheme.red : SebenzaTheme.amber;
                return ListTile(
                  title: Text(DateFormat('dd MMM yyyy').format(o.workDate),
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('${TimeCalc.formatHours(o.hours)} overtime',
                      style: const TextStyle(fontSize: 12, color: SebenzaTheme.muted)),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(border: Border.all(color: color),
                        borderRadius: BorderRadius.circular(4)),
                    child: Text(o.status.toUpperCase(),
                        style: TextStyle(color: color, fontSize: 11,
                            fontWeight: FontWeight.w700))),
                );
              }),
    );
  }
}

class OvertimeRequestView extends StatefulWidget {
  const OvertimeRequestView({super.key});
  @override
  State<OvertimeRequestView> createState() => _OvertimeRequestViewState();
}

class _OvertimeRequestViewState extends State<OvertimeRequestView> {
  final _hours = TextEditingController();
  final _reason = TextEditingController();
  final _form = GlobalKey<FormState>();
  Attendance? _target;

  Future<void> _submit() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    if (_target == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Choose the shift the overtime belongs to.')));
      return;
    }
    final vm = context.read<OvertimeVm>();
    final ok = await vm.submit(_target!.id, double.parse(_hours.text), _reason.text.trim());
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(vm.error ?? 'Could not submit the request.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<OvertimeVm>();
    final targets = vm.completed;
    _target ??= targets.isEmpty ? null : targets.first;
    return Scaffold(
      appBar: AppBar(title: const Text('Request Overtime')),
      body: targets.isEmpty
          ? const Center(child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('You need a completed shift before you can request overtime.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: SebenzaTheme.muted))))
          : Form(key: _form, child: ListView(padding: const EdgeInsets.all(20), children: [
              DropdownButtonFormField<Attendance>(
                initialValue: _target,
                decoration: const InputDecoration(labelText: 'SHIFT'),
                dropdownColor: SebenzaTheme.panel2,
                items: targets.map((a) => DropdownMenuItem(
                    value: a,
                    child: Text(
                      '${DateFormat('dd MMM yyyy').format(a.clockIn.toLocal())}  ·  '
                      'in ${DateFormat('HH:mm').format(a.clockIn.toLocal())}'
                      '${a.clockOut == null ? '' : ' – out ${DateFormat('HH:mm').format(a.clockOut!.toLocal())}'}',
                      style: const TextStyle(fontSize: 14),
                    )))
                    .toList(),
                onChanged: (v) => setState(() => _target = v)),
              const SizedBox(height: 16),
              TextFormField(controller: _hours,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                    labelText: 'OVERTIME HOURS', hintText: 'e.g. 1.5'),
                validator: (v) {
                  final h = double.tryParse(v ?? '');
                  if (h == null || h <= 0 || h > 12) return 'Enter hours between 0 and 12';
                  return null;
                }),
              const SizedBox(height: 16),
              TextFormField(controller: _reason, maxLines: 4,
                decoration: const InputDecoration(
                    labelText: 'REASON FOR OVERTIME',
                    hintText: 'Describe the work performed…'),
                validator: (v) =>
                    (v == null || v.trim().length < 3) ? 'A reason is required' : null),
              const SizedBox(height: 20),
              SizedBox(width: double.infinity, height: 50,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                      backgroundColor: SebenzaTheme.amber,
                      foregroundColor: const Color(0xFF141414),
                      textStyle: const TextStyle(
                          fontWeight: FontWeight.w800, letterSpacing: 1)),
                  onPressed: vm.busy ? null : _submit,
                  child: vm.busy
                      ? const SizedBox(width: 20, height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Color(0xFF141414)))
                      : const Text('SUBMIT REQUEST'))),
              const SizedBox(height: 10),
              SizedBox(width: double.infinity, height: 46,
                child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('CANCEL'))),
              const SizedBox(height: 14),
              const Text('Your request will be reviewed by a manager. '
                  'You will see the outcome on this screen.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: SebenzaTheme.muted, fontSize: 12)),
              if (vm.error != null)
                Padding(padding: const EdgeInsets.only(top: 12),
                  child: Text(vm.error!,
                      style: const TextStyle(color: SebenzaTheme.red))),
            ])),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../data/models.dart';
import '../viewmodels/viewmodels.dart';

class CorrectionRequestView extends StatefulWidget {
  final Attendance record;
  const CorrectionRequestView({super.key, required this.record});
  @override
  State<CorrectionRequestView> createState() => _CorrectionRequestViewState();
}

class _CorrectionRequestViewState extends State<CorrectionRequestView> {
  String field = 'clock_out';
  final _newValue = TextEditingController();
  final _reason = TextEditingController();
  final _form = GlobalKey<FormState>();

  Future<void> _submit() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    final vm = context.read<CorrectionVm>();
    final ok = await vm.submit(
        widget.record.id, field, _newValue.text.trim(), _reason.text.trim());
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Correction request submitted for review.')));
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(vm.error ?? 'Could not submit the request.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CorrectionVm>();
    return Scaffold(
      appBar: AppBar(title: const Text('Request Correction')),
      body: Form(key: _form, child: ListView(padding: const EdgeInsets.all(20), children: [
        Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('RECORD', style: TextStyle(fontSize: 10, color: SebenzaTheme.muted)),
          Text('In: ${widget.record.clockIn.toLocal()}',
              style: const TextStyle(fontSize: 13)),
          Text('Out: ${widget.record.clockOut?.toLocal() ?? '—'}',
              style: const TextStyle(fontSize: 13)),
        ]))),
        const SizedBox(height: 20),
        DropdownButtonFormField<String>(
          initialValue: field,
          decoration: const InputDecoration(labelText: 'FIELD TO CORRECT'),
          dropdownColor: SebenzaTheme.panel2,
          items: const [
            DropdownMenuItem(value: 'clock_in', child: Text('Clock in time')),
            DropdownMenuItem(value: 'clock_out', child: Text('Clock out time')),
            DropdownMenuItem(value: 'break_minutes', child: Text('Break minutes')),
          ],
          onChanged: (v) => setState(() => field = v!)),
        const SizedBox(height: 16),
        TextFormField(controller: _newValue,
          decoration: InputDecoration(labelText: 'NEW VALUE',
              hintText: field == 'break_minutes' ? 'e.g. 30' : 'YYYY-MM-DD HH:MM'),
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Enter the corrected value';
            if (field == 'break_minutes' && int.tryParse(v.trim()) == null) {
              return 'Enter minutes as a number';
            }
            return null;
          }),
        const SizedBox(height: 16),
        TextFormField(controller: _reason, maxLines: 3,
          decoration: const InputDecoration(labelText: 'REASON'),
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
            child: const Text('SUBMIT REQUEST'))),
        if (vm.error != null)
          Padding(padding: const EdgeInsets.only(top: 12),
            child: Text(vm.error!,
                style: const TextStyle(color: SebenzaTheme.red))),
        const SizedBox(height: 16),
        const Text('Corrections are reviewed by management before being applied. '
            'The original record is preserved in the audit log.',
            style: TextStyle(color: SebenzaTheme.muted, fontSize: 12)),
      ])),
    );
  }
}

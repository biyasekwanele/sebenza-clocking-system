import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../viewmodels/viewmodels.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthVm>();
    final e = auth.employee;
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        const CircleAvatar(radius: 36, backgroundColor: SebenzaTheme.panel2,
            child: Icon(Icons.person, size: 40, color: SebenzaTheme.muted)),
        const SizedBox(height: 16),
        Center(child: Text(e?.fullName ?? '',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600))),
        Center(child: Text(e?.employeeCode ?? '',
            style: const TextStyle(color: SebenzaTheme.amber))),
        const SizedBox(height: 28),
        _row('Email', e?.email ?? '—'),
        _row('Department', e?.departmentName ?? '—'),
        _row('Role', e?.role ?? '—'),
        const SizedBox(height: 32),
        SizedBox(width: double.infinity, height: 48,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
                side: const BorderSide(color: SebenzaTheme.red),
                foregroundColor: SebenzaTheme.red),
            onPressed: () async { await auth.signOut(); },
            child: const Text('SIGN OUT'))),
        const SizedBox(height: 16),
        const Text('Sebenza Clocking System v1.0', textAlign: TextAlign.center,
            style: TextStyle(color: SebenzaTheme.muted, fontSize: 11)),
      ]),
    );
  }

  Widget _row(String k, String v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(k, style: const TextStyle(
          color: SebenzaTheme.muted, fontSize: 12, letterSpacing: .5)),
      Text(v, style: const TextStyle(fontWeight: FontWeight.w500)),
    ]));
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/api.dart';
import '../viewmodels/viewmodels.dart';
import 'clock_view.dart';
import 'history_view.dart';
import 'monthly_hours_view.dart';
import 'overtime_view.dart';
import 'payslip_view.dart';
import 'profile_view.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int tab = 0;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (c) => ClockVm(c.read<Api>())..refresh()),
        ChangeNotifierProvider(create: (c) => HistoryVm(c.read<Api>())..load()),
        ChangeNotifierProvider(create: (c) => OvertimeVm(c.read<Api>())..load()),
        ChangeNotifierProvider(create: (c) => CorrectionVm(c.read<Api>())..load()),
        ChangeNotifierProvider(create: (c) => PayslipVm(c.read<Api>())..load()),
      ],
      child: Scaffold(
        body: IndexedStack(index: tab, children: const [
          ClockView(), HistoryView(), OvertimeView(),
          MonthlyHoursView(), PayslipView(), ProfileView()]),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: tab,
          onTap: (i) => setState(() => tab = i),
          selectedFontSize: 10,
          unselectedFontSize: 10,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.access_time), label: 'Clock'),
            BottomNavigationBarItem(icon: Icon(Icons.assignment_outlined), label: 'History'),
            BottomNavigationBarItem(icon: Icon(Icons.add), label: 'Overtime'),
            BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Hours'),
            BottomNavigationBarItem(icon: Icon(Icons.payments_outlined), label: 'Payslip'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
          ]),
      ),
    );
  }
}

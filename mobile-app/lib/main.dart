import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/theme.dart';
import 'data/api.dart';
import 'viewmodels/viewmodels.dart';
import 'views/app_shell.dart';
import 'views/login_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const url = String.fromEnvironment('SUPABASE_URL',
      defaultValue: 'https://lvwjsglxxzexefdapvjb.supabase.co');
  const anonKey = String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue:
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imx2d2pzZ2x4eHpleGVmZGFwdmpiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTE5MTk4MTIsImV4cCI6MjEwNzQ5NTgxMn0.lkoEcffENK9o4p8tZqS-k3fRn1sKKKbxwroHJwwLWRA');
  await Supabase.initialize(url: url, publishableKey: anonKey);
  runApp(const SebenzaApp());
}

class SebenzaApp extends StatelessWidget {
  const SebenzaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<Api>(create: (_) => Api()),
        ChangeNotifierProvider(create: (c) => AuthVm(c.read<Api>())),
      ],
      child: MaterialApp(
        title: 'Sebenza Clocking',
        debugShowCheckedModeBanner: false,
        theme: SebenzaTheme.dark(),
        home: Consumer<AuthVm>(
          builder: (_, auth, __) => auth.employee == null
              ? LoginView(onSignedIn: () => auth.loadProfile())
              : const AppShell(),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../viewmodels/viewmodels.dart';

class LoginView extends StatefulWidget {
  final VoidCallback onSignedIn;
  const LoginView({super.key, required this.onSignedIn});
  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _code = TextEditingController();
  final _password = TextEditingController();
  final _form = GlobalKey<FormState>();

  Future<void> _submit() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    final auth = context.read<AuthVm>();
    final ok = await auth.signIn(_code.text, _password.text);
    if (ok && mounted) widget.onSignedIn();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthVm>();
    return Scaffold(
      body: SafeArea(child: Center(child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 380),
          child: Form(key: _form, child: Column(children: [
            const Text('Sebenza',
                style: TextStyle(fontSize: 42, fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w700, color: SebenzaTheme.amber,
                    fontFamily: 'serif')),
            const Text('CLOCKING SYSTEM',
                style: TextStyle(color: SebenzaTheme.muted, letterSpacing: 3, fontSize: 11)),
            const SizedBox(height: 36),
            TextFormField(controller: _code,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                  labelText: 'EMPLOYEE ID OR EMAIL', hintText: 'e.g. E001'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Enter your employee ID' : null),
            const SizedBox(height: 16),
            TextFormField(controller: _password, obscureText: true,
              decoration: const InputDecoration(labelText: 'PASSWORD'),
              validator: (v) => (v == null || v.isEmpty) ? 'Enter your password' : null,
              onFieldSubmitted: (_) => _submit()),
            const SizedBox(height: 26),
            SizedBox(width: double.infinity, height: 50,
              child: FilledButton(
                style: FilledButton.styleFrom(
                    backgroundColor: SebenzaTheme.amber,
                    foregroundColor: const Color(0xFF141414),
                    textStyle: const TextStyle(
                        fontWeight: FontWeight.w800, letterSpacing: 1)),
                onPressed: auth.busy ? null : _submit,
                child: auth.busy
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Color(0xFF141414)))
                    : const Text('SIGN IN'))),
            if (auth.error != null)
              Padding(padding: const EdgeInsets.only(top: 16),
                child: Text(auth.error!,
                    style: const TextStyle(color: SebenzaTheme.red),
                    textAlign: TextAlign.center)),
            const SizedBox(height: 20),
            const Text('Forgot password? Contact HR.',
                style: TextStyle(color: SebenzaTheme.muted, fontSize: 12)),
          ]))),
      ))),
    );
  }
}

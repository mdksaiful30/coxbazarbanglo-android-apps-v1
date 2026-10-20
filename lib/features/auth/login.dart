import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../../core/api.dart';
import '../../core/session.dart';
import '../../widgets/brand_logo.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final email = TextEditingController(),
      password = TextEditingController(),
      base = TextEditingController(text: Session.defaultApi),
      resetToken = TextEditingController(),
      confirmation = TextEditingController();
  final keyForm = GlobalKey<FormState>();
  String mode = 'login';
  bool busy = false, hidden = true;
  String? error, message;
  @override
  void dispose() {
    for (final c in [email, password, base, resetToken, confirmation]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> submit() async {
    if (!keyForm.currentState!.validate()) return;
    final session = AppScope.of(context);
    setState(() {
      busy = true;
      error = null;
      message = null;
    });
    try {
      if (mode == 'login') {
        await session.login(base.text, email.text, password.text);
      } else {
        final api = Api()..baseUrl = Api.normalizeBase(base.text);
        await api.send(
          'POST',
          mode == 'forgot' ? 'auth/forgot-password' : 'auth/reset-password',
          {
            'email': email.text.trim(),
            if (mode == 'reset') ...{
              'token': resetToken.text.trim(),
              'password': password.text,
              'password_confirmation': confirmation.text,
            },
          },
        );
        if (mounted) {
          setState(
            () => message = mode == 'forgot'
                ? 'If the account exists, a reset link has been requested. Check your email.'
                : 'Password reset. You can now sign in.',
          );
        }
      }
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final form = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 440),
      child: Form(
        key: keyForm,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Center(child: BrandLogo()),
            const SizedBox(height: 24),
            Text(
              'COX’S BAZAR · BIWTA',
              style: Theme.of(context).textTheme.labelLarge
                  ?.copyWith(letterSpacing: 2),
            ),
            const SizedBox(height: 12),
            Text(
              mode == 'login'
                  ? s.label('Welcome back', 'স্বাগতম')
                  : mode == 'forgot'
                  ? 'Recover your account'
                  : 'Reset password',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'Rest-house reservations and guest care, wherever you work.',
            ),
            const SizedBox(height: 28),
            if (error != null || s.startupError != null) ...[
              Text(
                error ?? s.startupError!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              const SizedBox(height: 16),
            ],
            if (message != null) ...[
              Text(message!),
              const SizedBox(height: 16),
            ],
            TextFormField(
              controller: email,
              enabled: !busy,
              autofillHints: const [AutofillHints.username],
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email address'),
              validator: (v) =>
                  (v ?? '').contains('@') ? null : 'Enter your email',
            ),
            const SizedBox(height: 18),
            if (mode == 'reset') ...[
              TextFormField(
                controller: resetToken,
                decoration: const InputDecoration(
                  labelText: 'Reset token from email',
                ),
                validator: (v) =>
                    (v ?? '').isEmpty ? 'Enter your reset token' : null,
              ),
              const SizedBox(height: 18),
            ],
            if (mode != 'forgot') ...[
              TextFormField(
                controller: password,
                enabled: !busy,
                obscureText: hidden,
                autofillHints: const [AutofillHints.password],
                onFieldSubmitted: (_) => busy ? null : submit(),
                decoration: InputDecoration(
                  labelText: 'Password',
                  suffixIcon: IconButton(
                    tooltip: 'Show or hide password',
                    onPressed: () => setState(() => hidden = !hidden),
                    icon: Icon(
                      hidden
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
                validator: (v) => (v ?? '').isEmpty
                    ? 'Enter your password'
                    : mode == 'reset' && v!.length < 12
                    ? 'Minimum 12 characters'
                    : null,
              ),
              const SizedBox(height: 18),
            ],
            if (mode == 'reset') ...[
              TextFormField(
                controller: confirmation,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm password',
                ),
                validator: (v) =>
                    v != password.text ? 'Passwords must match' : null,
              ),
              const SizedBox(height: 18),
            ],
            FilledButton(
              onPressed: busy ? null : submit,
              child: Text(
                busy
                    ? 'Please wait…'
                    : mode == 'login'
                    ? 'Sign in'
                    : mode == 'forgot'
                    ? 'Request reset link'
                    : 'Reset password',
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.center,
              children: [
                TextButton(
                  onPressed: busy
                      ? null
                      : () => setState(() {
                          mode = mode == 'login' ? 'forgot' : 'login';
                          error = null;
                          message = null;
                        }),
                  child: Text(
                    mode == 'login' ? 'Forgot password?' : 'Back to sign in',
                  ),
                ),
                if (mode == 'forgot')
                  TextButton(
                    onPressed: () => setState(() => mode = 'reset'),
                    child: const Text('I have a reset token'),
                  ),
              ],
            ),
            if (!kReleaseMode)
              ExpansionTile(
                title: const Text('Server connection'),
                tilePadding: EdgeInsets.zero,
                children: [
                  TextFormField(
                    controller: base,
                    enabled: !busy,
                    decoration: const InputDecoration(
                      labelText: 'Laravel API URL',
                      helperText:
                          'Physical devices need your computer’s LAN address.',
                    ),
                    validator: (v) {
                      try {
                        Api.normalizeBase(v ?? '');
                        return null;
                      } catch (e) {
                        return '$e';
                      }
                    },
                  ),
                ],
              ),
            const SizedBox(height: 24),
            const Text(
              'Authorized admin and staff access only.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              "Developed by Zaman's Dev",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, c) => Row(
            children: [
              if (c.maxWidth >= 1000)
                Expanded(
                  child: Container(
                    color: const Color(0xff123f38),
                    padding: const EdgeInsets.all(64),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        BrandLogo(),
                        SizedBox(height: 40),
                        Text(
                          'A welcoming stay.\nA well-managed\nrest house.',
                          style: TextStyle(
                            fontSize: 44,
                            height: 1.2,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 24),
                        Text(
                          'কক্সবাজার পরিদর্শন বাংলো',
                          style: TextStyle(
                            color: Color(0xffbdd7c8),
                            fontSize: 22,
                          ),
                        ),
                        SizedBox(height: 32),
                        Text(
                          '14 rooms  ·  3 floors  ·  One clear view',
                          style: TextStyle(color: Color(0xffbdd7c8)),
                        ),
                      ],
                    ),
                  ),
                ),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(c.maxWidth < 600 ? 24 : 48),
                    child: form,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

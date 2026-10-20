import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/session.dart';
import '../widgets/common.dart';
import '../widgets/record_form.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});
  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  List<Json> devices = [];
  bool busy = false;
  String? error;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => load());
  }

  Future<void> load() async {
    try {
      final r = await AppScope.of(context).api.get('auth/devices');
      if (mounted) setState(() => devices = rows(r['data']));
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    }
  }

  Future<void> perform(Future<void> Function() fn) async {
    setState(() => busy = true);
    try {
      await fn();
    } catch (e) {
      if (mounted) notice(context, '$e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> password() async {
    final s = AppScope.of(context);
    await adaptiveDialog<bool>(
      context,
      RecordForm(
        title: 'Change password',
        message: 'Minimum 12 characters. Changing the password revokes every mobile session, including this one.',
        fields: const [
          FormFieldSpec(
            'current_password',
            'Current password',
            required: true,
            secret: true,
          ),
          FormFieldSpec(
            'password',
            'New password',
            required: true,
            secret: true,
          ),
          FormFieldSpec(
            'password_confirmation',
            'Confirm new password',
            required: true,
            secret: true,
          ),
        ],
        save: (v) async {
          await s.api.send('PUT', 'auth/password', v);
          s.expire();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        PageHeading(
          s.label('Your account', 'আপনার অ্যাকাউন্ট'),
          'Profile, appearance and device access.',
        ),
        Panel(
          child: DataFields({
            'Name': s.user?['name'],
            'Email': s.user?['email'],
            'Role': human(s.user?['role']),
            'API server': s.api.baseUrl,
          }),
        ),
        const SizedBox(height: 20),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Appearance', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 20),
              FieldGrid([
                DropdownButtonFormField<ThemeMode>(
                  key: ValueKey(s.theme),
                  initialValue: s.theme,
                  decoration: const InputDecoration(labelText: 'Theme'),
                  items: ThemeMode.values
                      .map(
                        (m) => DropdownMenuItem(
                          value: m,
                          child: Text(human(m.name)),
                        ),
                      )
                      .toList(),
                  onChanged: busy
                      ? null
                      : (m) => perform(() => s.preferences(m!, s.language)),
                ),
                DropdownButtonFormField<String>(
                  key: ValueKey(s.language),
                  initialValue: s.language,
                  decoration: const InputDecoration(
                    labelText: 'Navigation language',
                  ),
                  items: const [
                    DropdownMenuItem(value: 'en', child: Text('English')),
                    DropdownMenuItem(value: 'bn', child: Text('বাংলা')),
                  ],
                  onChanged: busy
                      ? null
                      : (lang) => perform(() => s.preferences(s.theme, lang!)),
                ),
              ]),
              const SizedBox(height: 12),
              const Text(
                'English: Roboto. বাংলা: Noto Sans Bengali. System theme follows your device.',
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Security & devices',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  OutlinedButton(
                    onPressed: busy ? null : password,
                    child: const Text('Change password'),
                  ),
                  FilledButton.icon(
                    onPressed: busy ? null : () => perform(s.logout),
                    icon: const Icon(Icons.logout),
                    label: const Text('Sign out'),
                  ),
                ],
              ),
              if (error != null) Text(error!),
              ...devices.map(
                (d) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(text(d['name'])),
                  subtitle: Text('Expires ${timestamp(d['expires_at'])}'),
                  trailing: IconButton(
                    tooltip: 'Revoke device',
                    onPressed: busy
                        ? null
                        : () async {
                            final api = s.api;
                            final ok = await adaptiveDialog<bool>(
                              context,
                              RecordForm(
                                title: 'Revoke device',
                                fields: const [],
                                message: 'This device will need to sign in again. If it is your current device, your session ends.',
                                saveLabel: 'Revoke',
                                save: (_) async {
                                  await api.request(
                                    'DELETE',
                                    'auth/devices/${d['id']}',
                                  );
                                },
                              ),
                            );
                            if (ok == true) {
                              try {
                                await s.api.get('auth/me');
                                await load();
                              } catch (_) {
                                s.expire();
                              }
                            }
                          },
                    icon: const Icon(Icons.phonelink_erase),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

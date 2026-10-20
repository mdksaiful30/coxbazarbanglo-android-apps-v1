import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/semantics.dart';

import 'core/session.dart';
import 'core/theme.dart';
import 'features/auth/login.dart';
import 'features/shell.dart';
import 'widgets/brand_logo.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Keep web controls available to screen readers and keyboard users from startup.
  if (kIsWeb) {
    SemanticsBinding.instance.ensureSemantics();
  }
  final session = Session();
  runApp(CoxBangloApp(session: session));
  session.restore();
}

class CoxBangloApp extends StatelessWidget {
  const CoxBangloApp({super.key, required this.session});
  final Session session;
  @override
  Widget build(BuildContext context) => AppScope(
    session: session,
    child: ListenableBuilder(
      listenable: session,
      builder: (context, _) => MaterialApp(
        title: 'Coxbazarbanglo',
        debugShowCheckedModeBanner: false,
        theme: appTheme(Brightness.light),
        darkTheme: appTheme(Brightness.dark),
        themeMode: session.theme,
        home: session.starting
            ? const Scaffold(
                body: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      BrandLogo(),
                      SizedBox(height: 24),
                      CircularProgressIndicator(),
                    ],
                  ),
                ),
              )
            : session.user == null
            ? const LoginScreen()
            : const AppShell(),
      ),
    ),
  );
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:coxbanglo/main.dart';
import 'package:coxbanglo/core/session.dart';
import 'package:coxbanglo/widgets/brand_logo.dart';

import 'app_test.dart' show readySession;

void main() {
  for (final width in [320.0, 1440.0]) {
    for (final theme in [ThemeMode.light, ThemeMode.dark]) {
      testWidgets('Brand assets load at $width in $theme', (tester) async {
        tester.view.physicalSize = Size(width, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final session = Session()
          ..starting = false
          ..theme = theme;
        await tester.pumpWidget(CoxBangloApp(session: session));
        await tester.pumpAndSettle();
        expect(find.byType(BrandLogo), findsWidgets);
        expect(find.bySemanticsLabel('Coxbazarbanglo'), findsWidgets);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(
          CoxBangloApp(session: readySession()..theme = theme),
        );
        await tester.pumpAndSettle();
        expect(find.byType(BrandLogo), findsWidgets);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
  }
}

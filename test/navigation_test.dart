import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:coxbanglo/main.dart';
import 'package:coxbanglo/core/session.dart';
import 'package:coxbanglo/features/bookings/booking_editor.dart';
import 'package:coxbanglo/widgets/common.dart';

import 'app_test.dart' show readySession;

void main() {
  testWidgets('Every admin destination renders without layout exceptions', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(CoxBangloApp(session: readySession()));
    await tester.pumpAndSettle();
    for (final page in [
      'Calendar',
      'Bookings',
      'Rooms',
      'Guests',
      'Tariffs',
      'Reservations',
      'Reports',
      'Staff',
      'Notifications',
      'Audit trail',
      'Account',
    ]) {
      final navigation = find.widgetWithText(ListTile, page).first;
      await tester.ensureVisible(navigation);
      await tester.tap(navigation);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: page);
    }
  });
  testWidgets(
    'Phone editor remains scrollable with larger accessibility text',
    (tester) async {
      tester.view.physicalSize = const Size(320, 740);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        AppScope(
          session: readySession(),
          child: MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(1.5)),
              child: child!,
            ),
            home: Scaffold(
              body: Builder(
                builder: (context) => FilledButton(
                  onPressed: () =>
                      adaptiveDialog(context, const BookingEditor()),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('Save changes'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

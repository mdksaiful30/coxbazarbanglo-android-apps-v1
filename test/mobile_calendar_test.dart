import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:coxbanglo/main.dart';
import 'package:coxbanglo/core/api.dart';
import 'package:coxbanglo/core/session.dart';
import 'package:coxbanglo/widgets/common.dart';

class CalendarApi extends Api {
  final today = DateTime(dhakaNow().year, dhakaNow().month, dhakaNow().day);
  final starts = <String>[];
  final rooms = <Json>[
    {'id': 1, 'code': '201', 'name': 'বাঁকখালী সমুদ্র দর্শন কক্ষ'},
    {'id': 2, 'code': '202', 'name': 'মাতামুহুরী'},
    {'id': 3, 'code': '203', 'name': 'ইনানী'},
  ];
  @override
  Future<Json> get(String path, {Json? query}) async {
    if (path == 'catalog') {
      return {
        'data': {'rooms': rooms},
      };
    }
    if (path == 'calendar') {
      starts.add(query!['start'] as String);
      String date(int offset) => dateOnly(today.add(Duration(days: offset)));
      return {
        'data': {
          'entries': [
            {
              'room_id': 1,
              'booking_id': 1,
              'starts_at': date(0),
              'ends_at': date(1),
            },
            {
              'room_id': 3,
              'kind': 'maintenance',
              'starts_at': date(0),
              'ends_at': date(2),
            },
            {'room_id': 2, 'starts_at': null, 'ends_at': ''},
          ],
          'bookings': [
            {
              'id': 1,
              'number': 'DEMO-1',
              'status': 'confirmed',
              'guest_snapshot': {'name': 'Sample Confirmed'},
              'check_in_at': date(0),
              'check_out_at': date(1),
              'rooms': [rooms[0]],
            },
            {
              'id': 2,
              'number': 'DEMO-2',
              'status': 'pending_approval',
              'guest_snapshot': {'name': 'Sample Pending'},
              'check_in_at': date(1),
              'check_out_at': date(2),
              'rooms': [rooms[1]],
            },
          ],
        },
      };
    }
    return {'data': <String, dynamic>{}};
  }
}

void main() {
  Future<CalendarApi> mount(
    WidgetTester tester,
    Size size, {
    double scale = 1,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.platformDispatcher.textScaleFactorTestValue = scale;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final api = CalendarApi();
    final session = Session(api: api)
      ..starting = false
      ..theme = ThemeMode.dark
      ..user = {'id': 1, 'name': 'Demo', 'role': 'admin'};
    await tester.pumpWidget(CoxBangloApp(session: session));
    await tester.pumpAndSettle();
    if (size.width < 700) {
      await tester.tap(find.byType(NavigationDestination).at(1));
    } else {
      await tester.tap(find.widgetWithText(ListTile, 'Calendar'));
    }
    await tester.pumpAndSettle();
    return api;
  }

  for (final size in [
    const Size(320, 800),
    const Size(390, 844),
    const Size(540, 960),
  ]) {
    testWidgets(
      'Full mobile week fits $size and opens day details with large text',
      (tester) async {
        final api = await mount(tester, size, scale: 1.6);
        expect(
          find.byKey(const ValueKey('mobile-week-calendar')),
          findsOneWidget,
        );
        expect(find.byType(Table), findsNothing);
        for (var i = 0; i < 7; i++) {
          final rect = tester.getRect(find.byKey(ValueKey('week-date-$i')));
          expect(rect.left, greaterThanOrEqualTo(0));
          expect(rect.right, lessThanOrEqualTo(size.width));
        }
        expect(tester.takeException(), isNull);
        Future<void> openCell(int room, int day) async {
          final finder = find.byKey(ValueKey('week-cell-$room-$day'));
          await tester.ensureVisible(finder);
          await tester.pumpAndSettle();
          await tester.tap(finder);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }

        Future<void> closeSheet() async {
          Navigator.of(tester.element(find.text('View booking'))).pop();
          await tester.pumpAndSettle();
        }

        await openCell(1, 0);
        expect(find.text('Sample Confirmed'), findsOneWidget);
        expect(find.text('View booking'), findsOneWidget);
        await closeSheet();
        await openCell(2, 1);
        expect(find.text('Sample Pending'), findsOneWidget);
        await closeSheet();
        await openCell(3, 0);
        expect(find.text('Room block: maintenance'), findsOneWidget);
        Navigator.of(tester.element(find.text('Room block: maintenance')))
            .pop();
        await tester.pumpAndSettle();
        tester
            .state<ScrollableState>(find.byType(Scrollable).first)
            .position
            .jumpTo(0);
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Next week'));
        await tester.pumpAndSettle();
        expect(
          api.starts.last,
          dateOnly(api.today.add(const Duration(days: 7))),
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('Large tablet retains the weekly calendar table', (tester) async {
    await mount(tester, const Size(1280, 900));
    expect(find.byType(Table), findsOneWidget);
    expect(find.byKey(const ValueKey('mobile-week-calendar')), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

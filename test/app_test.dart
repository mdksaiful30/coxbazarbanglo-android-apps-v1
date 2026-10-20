import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:coxbanglo/core/api.dart';
import 'package:coxbanglo/core/session.dart';
import 'package:coxbanglo/main.dart';
import 'package:coxbanglo/features/bookings/booking_editor.dart';
import 'package:coxbanglo/widgets/common.dart';

class FakeApi extends Api {
  final room = <String, dynamic>{
    'id': 1,
    'code': 'R201',
    'name': 'বাঁকখালী',
    'available': true,
    'capacity': 2,
    'housekeeping': 'ready',
    'ac_type': 'ac',
  };
  @override
  Future<Json> get(String path, {Json? query}) async => switch (path) {
    'dashboard' => {
      'data': {
        'rooms': 14,
        'pending': 2,
        'occupied': 3,
        'arrivals': 1,
        'departures': 1,
        'collections_minor': 125000,
        'receivables_minor': 250000,
        'tariff_ready': true,
      },
    },
    'catalog' => {
      'data': {
        'rooms': [room],
        'categories': [
          {'id': 1, 'code': 'A', 'name': 'Office guests'},
        ],
        'tariffs': [],
      },
    },
    'guests' => {
      'data': [
        {'id': 1, 'name': 'Test Guest', 'mobile': '+8801712345678'},
      ],
    },
    'availability' => {
      'data': [
        room,
        {...room, 'id': 2, 'code': 'R202', 'available': false},
      ],
    },
    'bookings' => {
      'data': [
        {
          'id': 1,
          'number': 'CB-TEST',
          'status': 'pending_approval',
          'guest_snapshot': {'name': 'Test Guest'},
          'check_in_at': '2027-01-01 14:00:00',
          'check_out_at': '2027-01-04 12:00:00',
          'rooms': [room],
        },
      ],
    },
    'calendar' => {
      'data': {'entries': [], 'bookings': []},
    },
    _ => {'data': []},
  };
}

Session readySession({bool admin = true}) {
  final api = FakeApi()..baseUrl = 'https://test.invalid/api/v1';
  return Session(api: api)
    ..starting = false
    ..user = {
      'id': 7,
      'name': 'Test Operator',
      'role': admin ? 'admin' : 'staff_admin',
    }
    ..catalog = {
      'rooms': [api.room],
      'categories': [
        {'id': 1, 'code': 'A', 'name': 'Office guests'},
      ],
      'tariffs': [],
    };
}

class RecordingAdapter implements HttpClientAdapter {
  final headers = <String>[];
  int calls = 0;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    headers.add('${options.headers['Idempotency-Key']}');
    calls++;
    return ResponseBody.fromString(
      calls == 1 ? '{}' : '{"data":{"id":1}}',
      calls == 1 ? 503 : 200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  test('Uncertain mutations reuse their key; a completed new action gets a new key', () async {
    final adapter = RecordingAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    final api = Api(dio: dio)..baseUrl = 'https://test.invalid/api/v1';
    await expectLater(
      api.send('POST', 'bookings', {'guest_id': 1}),
      throwsA(isA<ApiFailure>()),
    );
    await api.send('POST', 'bookings', {'guest_id': 1});
    expect(adapter.headers[0], adapter.headers[1]);
    await api.send('POST', 'bookings', {'guest_id': 1});
    expect(adapter.headers[2], isNot(adapter.headers[1]));
  });
  test(
    'Token-bearing client rejects absolute foreign pagination URLs',
    () async {
      final api = Api()
        ..baseUrl = 'https://test.invalid/api/v1'
        ..token = 'secret';
      await expectLater(
        api.get('https://another.invalid/api'),
        throwsA(isA<ApiFailure>()),
      );
    },
  );
  test('Dhaka timestamps and currency use backend conventions', () {
    expect(dhakaInput(DateTime(2027, 1, 1, 14)), '2027-01-01T14:00:00+06:00');
    expect(timestamp('2027-01-01T08:00:00Z'), timestamp('2027-01-01 14:00:00'));
    expect(money(125000), contains('1,250.00'));
    expect(moneyInput('1250.10'), 125010);
    expect(moneyInput('0.01'), 1);
    expect(() => moneyInput('1.001'), throwsA(isA<ApiFailure>()));
  });
  for (final width in [320.0, 768.0, 1440.0]) {
    testWidgets('Dashboard adapts at width $width without overflow', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(CoxBangloApp(session: readySession()));
      await tester.pumpAndSettle();
      expect(find.text('A clear view of every stay'), findsOneWidget);
      expect(tester.takeException(), isNull);
      if (width < 700) {
        expect(find.byType(NavigationBar), findsOneWidget);
      } else {
        expect(find.byType(NavigationBar), findsNothing);
      }
    });
  }
  testWidgets('Staff navigation does not expose admin destinations', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(CoxBangloApp(session: readySession(admin: false)));
    await tester.pumpAndSettle();
    expect(find.text('Staff'), findsNothing);
    expect(find.text('Tariffs'), findsNothing);
    expect(find.text('Guests'), findsOneWidget);
  });
  testWidgets(
    'Booking editor disables conflicting rooms and validates missing input',
    (tester) async {
      tester.view.physicalSize = const Size(720, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final s = readySession();
      await tester.pumpWidget(
        AppScope(
          session: s,
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => FilledButton(
                  onPressed: () =>
                      adaptiveDialog(context, const BookingEditor()),
                  child: const Text('Open editor'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open editor'));
      await tester.pumpAndSettle();
      final chips = tester
          .widgetList<FilterChip>(find.byType(FilterChip))
          .toList();
      expect(chips.length, 2);
      expect(chips.last.onSelected, isNull);
      await tester.tap(find.text('Save changes'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Choose a guest'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

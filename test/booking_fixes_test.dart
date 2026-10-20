import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:coxbanglo/core/api.dart';
import 'package:coxbanglo/core/session.dart';
import 'package:coxbanglo/features/bookings/booking_document.dart';
import 'package:coxbanglo/features/bookings/booking_editor.dart';
import 'package:coxbanglo/features/bookings/booking_detail.dart';
import 'package:coxbanglo/widgets/common.dart';

import 'app_test.dart' show FakeApi, readySession;

final confirmation = <String, dynamic>{
  'number': 'CB-TEST',
  'version': 2,
  'status': 'confirmed',
  'property': {
    'name': "Cox's Bazar Inspection Bungalow",
    'address': "Cox's Bazar, Bangladesh",
  },
  'guest': {'name': 'পরীক্ষামূলক অতিথি', 'mobile': '+8801712345678'},
  'check_in_at': '2027-01-01 14:00:00',
  'check_out_at': '2027-01-03 12:00:00',
  'guest_count': 2,
  'category': 'Category A',
  'rooms': [
    {'code': 'R201', 'name': 'বাঁকখালী', 'ac_type': 'ac', 'floor': 'প্রথম তলা'},
  ],
  'finance': {
    'charges_minor': 500000,
    'paid_minor': 300000,
    'refunded_minor': 0,
    'balance_minor': 200000,
    'payment_status': 'partially_paid',
  },
  'generated_at': '2026-10-20T10:00:00+06:00',
};

class DocumentApi extends FakeApi {
  final requests = <String>[];
  @override
  Future<Json> get(String path, {Json? query}) async {
    requests.add(path);
    if (path == 'bookings/1/guest-confirmation') {
      return {'data': confirmation};
    }
    if (path == 'bookings/1') {
      return {
        'data': {
          'id': 1,
          'number': 'CB-TEST',
          'status': 'confirmed',
          'version': 2,
          'guest_snapshot': confirmation['guest'],
          'rooms': confirmation['rooms'],
        },
        'finance': confirmation['finance'],
      };
    }
    return super.get(path, query: query);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    for (final family in ['Roboto', 'NotoSansBengali']) {
      final loader = FontLoader(family)
        ..addFont(rootBundle.load('assets/fonts/$family.ttf'));
      await loader.load();
    }
  });

  testWidgets('New booking picker disables all dates before Dhaka today', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final session = readySession();
    await tester.pumpWidget(
      AppScope(
        session: session,
        child: const MaterialApp(home: Scaffold(body: BookingEditor())),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.textContaining('Arrival\n').first);
    await tester.tap(find.textContaining('Arrival\n').first);
    await tester.pumpAndSettle();
    final picker = tester.widget<DatePickerDialog>(
      find.byType(DatePickerDialog),
    );
    final now = dhakaNow();
    expect(picker.firstDate, DateTime(now.year, now.month, now.day));
  });

  testWidgets('PDF and JPG contain real file bytes with Bengali content', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final pdf = await BookingDocument.render(confirmation, 'pdf');
      final jpg = await BookingDocument.render(confirmation, 'jpg');
      expect(ascii.decode(pdf.take(5).toList()), '%PDF-');
      expect(jpg.take(3), [0xff, 0xd8, 0xff]);
      final decoded = img.decodeJpg(jpg)!;
      expect(decoded.width, 1191);
      expect(decoded.height, greaterThanOrEqualTo(1684));
      final output = Directory('build/booking-export-check')
        ..createSync(recursive: true);
      File('${output.path}/booking.pdf').writeAsBytesSync(pdf);
      File('${output.path}/booking.jpg').writeAsBytesSync(jpg);
    });
  });

  testWidgets(
    'Generate PDF fetches confirmation and offers the generated file',
    (tester) async {
      final api = DocumentApi();
      final session = Session(api: api)
        ..starting = false
        ..user = {'id': 1, 'role': 'admin'};
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        AppScope(
          session: session,
          child: const MaterialApp(home: BookingDetailScreen(id: 1)),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Generate PDF'));
      await tester.tap(find.text('Generate PDF'));
      for (var attempt = 0; attempt < 100; attempt++) {
        await tester.pump();
        await tester.runAsync(() async {
          await Future<void>.delayed(const Duration(milliseconds: 100));
        });
        if (find.text('Save PDF').evaluate().isNotEmpty) {
          break;
        }
      }
      await tester.pumpAndSettle();
      expect(api.requests, contains('bookings/1/guest-confirmation'));
      expect(find.text('Save PDF'), findsOneWidget);
      await tester.ensureVisible(find.text('Generate JPG'));
      await tester.tap(find.text('Generate JPG'));
      for (var attempt = 0; attempt < 100; attempt++) {
        await tester.pump();
        await tester.runAsync(() async {
          await Future<void>.delayed(const Duration(milliseconds: 100));
        });
        if (find.text('Save JPG').evaluate().isNotEmpty) {
          break;
        }
      }
      await tester.pumpAndSettle();
      expect(find.text('Save JPG'), findsOneWidget);
      expect(find.text('Share prepared file'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

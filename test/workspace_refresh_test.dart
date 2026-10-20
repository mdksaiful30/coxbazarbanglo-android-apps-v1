import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:coxbanglo/core/api.dart';
import 'package:coxbanglo/core/session.dart';
import 'package:coxbanglo/core/theme.dart';
import 'package:coxbanglo/features/overview.dart';
import 'package:coxbanglo/features/directory.dart';
import 'package:coxbanglo/features/bookings/booking_list.dart';
import 'package:coxbanglo/widgets/room_art.dart';

import 'app_test.dart' show FakeApi;

class WorkspaceApi extends FakeApi {
  final mutations = <String>[];
  @override
  Future<Json> get(String path, {Json? query}) async {
    if (path == 'guests') {
      return {
        'data': [
          {
            'id': 1,
            'name': 'Sample Guest With A Longer Name',
            'mobile': '+880 1XXX XXXXXX',
            'email': 'guest@example.com',
            'designation': 'Visiting officer',
            'organization': 'Sample organisation',
          },
        ],
      };
    }
    if (path == 'users') {
      return {
        'data': [
          {
            'id': 1,
            'name': 'Sample Administrator',
            'email': 'staff@example.com',
            'role': 'admin',
            'active': true,
          },
        ],
      };
    }
    if (path == 'notifications') {
      return {
        'data': [
          {
            'id': 1,
            'booking_id': 7,
            'channel': 'email',
            'status': 'failed',
            'destination': 'guest@example.com',
            'last_error': 'The message could not be delivered.',
            'provider_id': null,
            'created_at': '2026-10-19 12:30:00',
          },
        ],
      };
    }
    if (path == 'audit-logs') {
      return {
        'data': [
          {
            'id': 1,
            'action': 'booking_approved',
            'entity': 'booking',
            'entity_id': 7,
            'actor_id': 1,
            'created_at': '2026-10-19 12:30:00',
            'data': {},
          },
        ],
      };
    }
    return super.get(path, query: query);
  }

  @override
  Future<Json> send(
    String method,
    String path, [
    Json? data,
    String? idempotencyKey,
  ]) async {
    mutations.add(path);
    return {'data': {}};
  }
}

void main() {
  test('Room captions use bilingual names and preserve renamed rooms', () {
    expect(RoomArtwork.captionFor({'name': 'বাঁকখালী'}), 'Bakkhali\nবাঁকখালী');
    expect(RoomArtwork.captionFor({'name': 'Suite'}), 'Suite\nস্যুট');
    expect(
      RoomArtwork.captionFor({
        'name': 'Custom',
        'name_en': 'Sea View',
        'name_bn': 'সমুদ্র',
      }),
      'Sea View\nসমুদ্র',
    );
    expect(
      RoomArtwork.captionFor({'code': 'R201', 'name': 'New Room'}),
      'New Room',
    );
  });

  test('Room artwork follows supplied type and bed configuration', () {
    expect(
      RoomArtwork.assetFor({'name': 'অপেক্ষমান কক্ষ'}),
      'assets/rooms/waiting.jpg',
    );
    expect(
      RoomArtwork.assetFor({'room_type': 'suite'}),
      'assets/rooms/suite.jpg',
    );
    expect(
      RoomArtwork.assetFor({'ac_type': 'ac', 'bed_type': 'কাপল বেড'}),
      'assets/rooms/ac-double.jpg',
    );
    expect(
      RoomArtwork.assetFor({'ac_type': 'ac', 'bed_type': 'ডাবল বেড'}),
      'assets/rooms/ac-twin.jpg',
    );
    expect(
      RoomArtwork.assetFor({'ac_type': 'non_ac', 'bed_type': 'কাপল বেড'}),
      'assets/rooms/nonac-double.jpg',
    );
    expect(
      RoomArtwork.assetFor({'ac_type': 'non_ac', 'bed_type': 'ডাবল বেড'}),
      'assets/rooms/nonac-twin.jpg',
    );
  });
  for (final size in [
    const Size(320, 900),
    const Size(390, 844),
    const Size(1280, 900),
  ]) {
    for (final brightness in Brightness.values) {
      testWidgets(
        'Workspace pages fit $size in $brightness with enlarged text',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          tester.platformDispatcher.textScaleFactorTestValue = 1.5;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          final api = WorkspaceApi();
          final session = Session(api: api)
            ..starting = false
            ..user = {'id': 1, 'name': 'Sample Administrator', 'role': 'admin'}
            ..catalog = {
              'rooms': [api.room],
            };
          final pages = <Widget>[
            DashboardScreen(onBookings: () {}),
            const BookingListScreen(),
            const RoomsScreen(),
            for (final kind in [
              'Guests',
              'Staff',
              'Notifications',
              'Audit trail',
            ])
              DirectoryScreen(kind: kind),
          ];
          for (final page in pages) {
            await tester.pumpWidget(
              AppScope(
                session: session,
                child: MaterialApp(
                  theme: appTheme(brightness),
                  home: Scaffold(
                    body: KeyedSubtree(key: UniqueKey(), child: page),
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();
            expect(
              tester.takeException(),
              isNull,
              reason: page.runtimeType.toString(),
            );
          }
          expect(
            find.text('booking · #7'),
            findsOneWidget,
            reason: 'Audit cards use the actual entity field',
          );
          await tester.pumpWidget(const SizedBox.shrink());
        },
      );
    }
  }
  testWidgets('Notification retry still needs explicit confirmation', (
    tester,
  ) async {
    final api = WorkspaceApi();
    final session = Session(api: api)..user = {'role': 'admin'};
    await tester.pumpWidget(
      AppScope(
        session: session,
        child: MaterialApp(
          theme: appTheme(Brightness.light),
          home: const Scaffold(body: DirectoryScreen(kind: 'Notifications')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Retry delivery'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Retry delivery'));
    await tester.pumpAndSettle();
    expect(
      find.text('Confirm the provider has not already accepted this message.'),
      findsOneWidget,
    );
    expect(api.mutations, isEmpty);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

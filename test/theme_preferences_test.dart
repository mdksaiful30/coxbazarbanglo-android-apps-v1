import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:coxbanglo/core/api.dart';
import 'package:coxbanglo/core/session.dart';
import 'package:coxbanglo/main.dart';

class PreferenceApi extends Api {
  bool offline = true;
  Json? saved;
  @override
  Future<Json> send(String method, String path, [Json data = const {}]) async {
    if (offline) throw const ApiFailure('Offline');
    saved = data;
    return {'data': data};
  }

  @override
  Future<Json> get(String path, {Json? query}) async => {
    'data': path == 'auth/preferences'
        ? {'theme': 'light', 'language': 'en'}
        : {},
  };
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  testWidgets('Offline theme changes repaint the app and survive restart', (
    tester,
  ) async {
    final api = PreferenceApi()..baseUrl = Session.productionApi;
    final session = Session(api: api)..starting = false;
    await tester.pumpWidget(CoxBangloApp(session: session));
    await tester.pumpAndSettle();
    await expectLater(
      session.preferences(ThemeMode.dark, 'bn'),
      throwsA(isA<ApiFailure>()),
    );
    await tester.pumpAndSettle();
    expect(
      Theme.of(tester.element(find.byType(Scaffold).first)).brightness,
      Brightness.dark,
    );
    expect(session.language, 'bn');
    final restored = Session(api: PreferenceApi());
    await restored.restore();
    expect(restored.theme, ThemeMode.dark);
    expect(restored.language, 'bn');
    await expectLater(
      session.preferences(ThemeMode.light, 'en'),
      throwsA(isA<ApiFailure>()),
    );
    await tester.pumpAndSettle();
    expect(
      Theme.of(tester.element(find.byType(Scaffold).first)).brightness,
      Brightness.light,
    );
  });

  test(
    'Pending appearance syncs on account reload without stale overwrite',
    () async {
      final api = PreferenceApi()..baseUrl = Session.productionApi;
      final session = Session(api: api)..user = {'id': 7};
      await expectLater(
        session.preferences(ThemeMode.dark, 'bn'),
        throwsA(isA<ApiFailure>()),
      );
      api.offline = false;
      await session.loadAccount();
      expect(api.saved, {'theme': 'dark', 'language': 'bn'});
      expect(session.theme, ThemeMode.dark);
      expect(
        await session.storage.read(key: 'appearance_pending_owner'),
        isNull,
      );
    },
  );
}

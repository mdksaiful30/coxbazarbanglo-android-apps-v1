import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'api.dart';

class Session extends ChangeNotifier {
  Session({Api? api, FlutterSecureStorage? storage})
    : api = api ?? Api(),
      storage = storage ?? const FlutterSecureStorage() {
    this.api.onUnauthorized = expire;
  }
  final Api api;
  final FlutterSecureStorage storage;
  Json? user;
  Json catalog = {};
  ThemeMode theme = ThemeMode.system;
  String language = 'en';
  bool starting = true;
  String? startupError;
  bool get admin => user?['role'] == 'admin';
  String label(String en, String bn) => language == 'bn' ? bn : en;

  static const productionApi =
      'https://coxbazarbanglo.learnwithzaman.com/api/v1';

  static String get defaultApi =>
      const String.fromEnvironment('API_BASE_URL', defaultValue: productionApi);

  Future<void> restore() async {
    // Appearance is a device preference too: restore it before any network call.
    try {
      theme = _themeMode(await storage.read(key: 'appearance_theme'));
      language = await storage.read(key: 'appearance_language') ?? 'en';
      notifyListeners();
    } catch (_) {
      // Restricted browser storage must not prevent sign-in.
    }
    try {
      final savedBase = await storage.read(key: 'api_base');
      final selectedBase = Api.normalizeBase(
        kReleaseMode ? defaultApi : (savedBase ?? defaultApi),
      );
      api.baseUrl = selectedBase;
      // Tokens belong to one server. Never migrate a local test token to production.
      if (savedBase == null || Api.normalizeBase(savedBase) == selectedBase) {
        api.token = await storage.read(key: 'access_token');
      } else {
        await storage.delete(key: 'access_token');
        await storage.write(key: 'api_base', value: selectedBase);
      }
      if (api.token != null) {
        user = object((await api.get('auth/me'))['data']);
        await loadAccount();
      }
    } catch (e) {
      startupError = '$e';
      user = null;
    }
    starting = false;
    notifyListeners();
  }

  Future<void> login(String base, String email, String password) async {
    final normalized = Api.normalizeBase(kReleaseMode ? defaultApi : base);
    // Do not send an existing token to a newly selected server.
    api.token = null;
    api.baseUrl = normalized;
    final result = object(
      (await api.send('POST', 'auth/mobile/login', {
        'email': email.trim(),
        'password': password,
        'device_name': kIsWeb
            ? 'Cox Banglo Web'
            : 'Cox Banglo ${defaultTargetPlatform.name}',
      }))['data'],
    );
    api.token = result['token'] as String;
    try {
      await storage.write(key: 'api_base', value: normalized);
      await storage.write(key: 'access_token', value: api.token);
    } catch (_) {
      // A usable session remains in memory when browser secure storage is unavailable.
    }
    user = object(result['user']);
    startupError = null;
    try {
      await loadAccount();
    } catch (_) {
      /* The shell exposes retryable page errors. */
    }
    notifyListeners();
  }

  Future<void> loadCatalog() async {
    catalog = object((await api.get('catalog'))['data']);
  }

  static ThemeMode _themeMode(String? value) => switch (value) {
    'dark' => ThemeMode.dark,
    'light' => ThemeMode.light,
    _ => ThemeMode.system,
  };

  String get _preferenceOwner => '${api.baseUrl}|${user?['id']}';

  Future<void> _saveAppearance() async {
    try {
      await storage.write(key: 'appearance_theme', value: theme.name);
      await storage.write(key: 'appearance_language', value: language);
    } catch (_) {
      // Appearance remains usable in memory if device storage is unavailable.
    }
  }

  Future<void> loadAccount() async {
    try {
      final pending = await storage.read(key: 'appearance_pending_owner');
      if (pending == _preferenceOwner) {
        await preferences(
          _themeMode(await storage.read(key: 'appearance_pending_theme')),
          await storage.read(key: 'appearance_pending_language') ?? 'en',
        );
      } else {
        final saved = object((await api.get('auth/preferences'))['data']);
        theme = _themeMode(saved['theme'] as String?);
        language = text(saved['language'], 'en');
        notifyListeners();
        await _saveAppearance();
      }
    } finally {
      await loadCatalog();
    }
  }

  Future<void> preferences(ThemeMode mode, String lang) async {
    // Apply immediately: a slow or unavailable API must not block appearance.
    theme = mode;
    language = lang;
    notifyListeners();
    await _saveAppearance();
    try {
      await storage.write(key: 'appearance_pending_theme', value: mode.name);
      await storage.write(key: 'appearance_pending_language', value: lang);
    } catch (_) {
      /* Device storage may be unavailable. */
    }

    try {
      await storage.write(
        key: 'appearance_pending_owner',
        value: _preferenceOwner,
      );
    } catch (_) {
      // Network sync can still succeed without persistent storage.
    }
    try {
      await api.send('PATCH', 'auth/preferences', {
        'theme': mode.name,
        'language': lang,
      });
    } catch (_) {
      throw const ApiFailure(
        'Appearance applied on this device. Account sync failed; it will retry when your account reloads.',
      );
    }
    try {
      await storage.delete(key: 'appearance_pending_owner');
    } catch (_) {
      // A repeated preference update is safe on the next account load.
    }
  }

  Future<void> logout() async {
    // Only clear the local session after the server revokes this device token.
    await api.send('POST', 'auth/logout');
    expire();
  }

  void expire() {
    api.token = null;
    user = null;
    catalog = {};
    storage.delete(key: 'access_token').catchError((_) {});
    notifyListeners();
  }
}

class AppScope extends InheritedNotifier<Session> {
  const AppScope({super.key, required Session session, required super.child})
    : super(notifier: session);
  static Session of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;
}

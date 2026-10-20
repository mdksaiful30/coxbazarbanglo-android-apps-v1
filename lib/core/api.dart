import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

typedef Json = Map<String, dynamic>;
Json object(dynamic value) =>
    value is Map ? Map<String, dynamic>.from(value) : {};
List<Json> rows(dynamic value) =>
    value is List ? value.map(object).toList() : [];
String text(dynamic value, [String fallback = '—']) =>
    value == null || value.toString().isEmpty ? fallback : value.toString();
int number(dynamic value) =>
    value is num ? value.toInt() : int.tryParse('$value') ?? 0;

class ApiFailure implements Exception {
  const ApiFailure(this.message, {this.status, this.errors = const {}});
  final String message;
  final int? status;
  final Json errors;
  @override
  String toString() => message;
}

/// One client for every feature. The backend owns all booking and pricing rules.
class Api {
  Api({Dio? dio})
    : dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 60),
            ),
          );
  final Dio dio;
  String baseUrl = '';
  String? token;
  VoidCallback? onUnauthorized;
  final Map<String, String> _pendingKeys = {};

  static String normalizeBase(String input) {
    final uri = Uri.tryParse(input.trim());
    if (uri == null ||
        !['http', 'https'].contains(uri.scheme) ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment) {
      throw const ApiFailure(
        'Enter an API address such as https://your-domain.com/api/v1.',
      );
    }
    if (!kDebugMode &&
        uri.scheme != 'https' &&
        !const bool.fromEnvironment('ALLOW_HTTP')) {
      throw const ApiFailure('Release builds require an HTTPS API address.');
    }
    final url = input.trim().replaceAll(RegExp(r'/+$'), '');
    return url.endsWith('/api/v1') ? url : '$url/api/v1';
  }

  Future<dynamic> request(
    String method,
    String path, {
    dynamic data,
    Json? query,
    ResponseType? responseType,
  }) async {
    // Accept only relative paths: a pagination URL must never send the token elsewhere.
    if (path.contains('://') || path.startsWith('//')) {
      throw const ApiFailure('Invalid API path.');
    }
    final mutation = !['GET', 'HEAD'].contains(method);
    final fingerprint = mutation && data is! FormData
        ? '$method:$path:${jsonEncode(data)}'
        : null;
    final key = mutation
        ? (fingerprint == null
              ? const Uuid().v4()
              : _pendingKeys.putIfAbsent(fingerprint, () => const Uuid().v4()))
        : null;
    try {
      final result = await dio.request(
        '$baseUrl/${path.replaceFirst(RegExp(r'^/'), '')}',
        data: data,
        queryParameters: query,
        options: Options(
          method: method,
          responseType: responseType,
          headers: {
            'Accept': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
            'Idempotency-Key': ?key,
          },
        ),
      );
      if (fingerprint != null) _pendingKeys.remove(fingerprint);
      return result.data;
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (fingerprint != null && status != null && status < 500) {
        _pendingKeys.remove(fingerprint);
      }
      if (status == 401) onUnauthorized?.call();
      final body = object(e.response?.data);
      final errors = object(body['errors']);
      final detail = errors.values
          .expand((v) => v is List ? v : [v])
          .join('\n');
      throw ApiFailure(
        detail.isNotEmpty
            ? detail
            : text(
                body['message'],
                status == null
                    ? 'Cannot reach the server. Check your connection and API address. For an uncertain save, retry unchanged to reuse its request key.'
                    : status == 409
                    ? 'This record changed or the rooms are no longer available. Reload and review it.'
                    : 'Request failed ($status).',
              ),
        status: status,
        errors: errors,
      );
    }
  }

  Future<Json> get(String path, {Json? query}) async =>
      object(await request('GET', path, query: query));
  Future<Json> send(String method, String path, [Json data = const {}]) async =>
      object(await request(method, path, data: data));
  Future<Uint8List> download(String path) async => Uint8List.fromList(
    List<int>.from(
      await request('GET', path, responseType: ResponseType.bytes),
    ),
  );
  Future<void> upload(String path, String name, Uint8List bytes) async {
    await request(
      'POST',
      path,
      data: FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: name),
      }),
    );
  }
}

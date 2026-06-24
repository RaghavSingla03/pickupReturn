import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  static const String baseUrl = 'https://api.trucksreturn.com/api';
  static const _storage = FlutterSecureStorage();

  late final Dio _dio;
  static final ApiClient instance = ApiClient._();

  void Function()? onUnauthorized;

  ApiClient._() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
      validateStatus: (s) => s != null && s < 500,
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: 'access_token');
        if (token != null) options.headers['Authorization'] = 'Bearer $token';
        handler.next(options);
      },
      onResponse: (response, handler) {
        if (response.statusCode == 401 && !_isAuthPath(response.requestOptions.path)) {
          _handleUnauthorized();
        }
        handler.next(response);
      },
      onError: (e, handler) {
        if (e.response?.statusCode == 401 && !_isAuthPath(e.requestOptions.path)) {
          _handleUnauthorized();
        }
        handler.next(e);
      },
    ));
  }

  bool _isAuthPath(String path) =>
      path.contains('/auth/login') ||
      path.contains('/auth/register') ||
      path.contains('/auth/send-otp') ||
      path.contains('/auth/forgot-password') ||
      path.contains('/auth/reset-password');

  void _handleUnauthorized() {
    _storage.delete(key: 'access_token');
    onUnauthorized?.call();
  }

  Dio get dio => _dio;

  Future<void> saveToken(String token) => _storage.write(key: 'access_token', value: token);
  Future<String?> getToken() => _storage.read(key: 'access_token');
  Future<void> clearToken() => _storage.delete(key: 'access_token');
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, [this.statusCode]);
  @override
  String toString() => message;
}

String extractError(dynamic err) {
  if (err is DioException) {
    final data = err.response?.data;
    if (data is Map) {
      return data['error']?.toString() ??
          data['message']?.toString() ??
          'Request failed';
    }
    return err.message ?? 'Network error';
  }
  return err?.toString() ?? 'Unknown error';
}

String extractResponseError(Response r) {
  final data = r.data;
  if (data is Map) {
    return data['error']?.toString() ??
        data['message']?.toString() ??
        'Request failed (${r.statusCode})';
  }
  return 'Request failed (${r.statusCode})';
}

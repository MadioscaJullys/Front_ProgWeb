import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'auth_service.dart';
import '../config/config.dart';

abstract class BaseApiService {
  // Usa a configuração centralizada
  static String get baseUrl => Config.apiUrl;

  final AuthService authService;
  late Dio dio;

  BaseApiService(this.authService) {
    dio = Dio();
    _configureDio();
  }

  void _configureDio() {
    dio.options.baseUrl = baseUrl;
    dio.options.connectTimeout = Config.connectTimeout;
    dio.options.receiveTimeout = Config.receiveTimeout;

    // Interceptor para adicionar token automaticamente
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (authService.token != null) {
            options.headers['Authorization'] = 'Bearer ${authService.token}';
          }
          options.headers['Content-Type'] = 'application/json';
          options.headers['Accept'] = 'application/json';
          // Debug: log outgoing request (helpful to debug 401/403)
          debugPrint('--> ${options.method.toUpperCase()} ${options.uri}');
          debugPrint('Headers: ${options.headers}');
          if (options.data != null) debugPrint('Request body: ${options.data}');
          handler.next(options);
        },
        onError: (error, handler) {
          debugPrint('API Error: ${error.message}');
          debugPrint(
            'Request that failed: ${error.requestOptions.method} ${error.requestOptions.uri}',
          );
          debugPrint('Request headers: ${error.requestOptions.headers}');
          debugPrint('Response status: ${error.response?.statusCode}');
          debugPrint('Response data: ${error.response?.data}');

          if (error.response?.statusCode == 403) {
            debugPrint(
              'Received 403 Forbidden — check backend permissions and the role/claims in the token.',
            );
          }
          handler.next(error);
        },
      ),
    );
  }
}

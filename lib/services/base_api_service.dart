import 'package:dio/dio.dart';
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
          handler.next(options);
        },
        onError: (error, handler) {
          print('API Error: ${error.message}');
          print('Response: ${error.response?.data}');
          handler.next(error);
        },
      ),
    );
  }
}

import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../models/models.dart';

class UserService extends ChangeNotifier {
  static const String baseUrl = 'http://localhost:8000';
  late Dio _dio;

  UserService() {
    _dio = Dio();
    _configureDio();
  }

  void _configureDio() {
    _dio.options.baseUrl = baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
    _dio.options.sendTimeout = const Duration(seconds: 30);

    if (kIsWeb) {
      _dio.options.headers.addAll({
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      });
    }
  }

  Future<List<User>> getUsers(String token) async {
    try {
      final response = await _dio.get(
        '/users',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => User.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Erro ao buscar usuários: $e');
      return [];
    }
  }

  Future<User?> getUser(String token, int userId) async {
    try {
      final response = await _dio.get(
        '/users/$userId',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        return User.fromJson(response.data);
      }
      return null;
    } catch (e) {
      debugPrint('Erro ao buscar usuário: $e');
      return null;
    }
  }

  Future<bool> createUser(String token, UserCreate userCreate) async {
    try {
      final response = await _dio.post(
        '/users',
        data: userCreate.toJson(),
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      return response.statusCode == 201;
    } catch (e) {
      debugPrint('Erro ao criar usuário: $e');
      return false;
    }
  }

  Future<bool> updateUser(
    String token,
    int userId,
    UserUpdate userUpdate,
  ) async {
    try {
      final response = await _dio.put(
        '/users/$userId',
        data: userUpdate.toJson(),
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Erro ao atualizar usuário: $e');
      return false;
    }
  }

  Future<bool> deleteUser(String token, int userId) async {
    try {
      final response = await _dio.delete(
        '/users/$userId',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Erro ao deletar usuário: $e');
      return false;
    }
  }
}

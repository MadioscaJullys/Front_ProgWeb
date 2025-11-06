import 'package:dio/dio.dart';
import '../models/models.dart';
import 'auth_service.dart';
import 'base_api_service.dart';

class UserApiService extends BaseApiService {
  UserApiService(AuthService authService) : super(authService);

  Future<List<User>> getUsers() async {
    try {
      final response = await dio.get('/users/');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => User.fromJson(json)).toList();
      }
      throw Exception('Falha ao carregar usuários');
    } catch (e) {
      if (e is DioException) {
        throw Exception('Erro: ${e.message}');
      }
      throw Exception('Erro: $e');
    }
  }

  Future<User> createUser(UserCreate user) async {
    try {
      final response = await dio.post('/users/', data: user.toJson());

      if (response.statusCode == 201) {
        return User.fromJson(response.data);
      }
      throw Exception('Falha ao criar usuário');
    } catch (e) {
      if (e is DioException) {
        throw Exception('Erro: ${e.message}');
      }
      throw Exception('Erro: $e');
    }
  }

  Future<User> updateUser(int id, UserUpdate user) async {
    try {
      final response = await dio.put('/users/$id', data: user.toJson());

      if (response.statusCode == 200) {
        return User.fromJson(response.data);
      }
      throw Exception('Falha ao atualizar usuário');
    } catch (e) {
      if (e is DioException) {
        throw Exception('Erro: ${e.message}');
      }
      throw Exception('Erro: $e');
    }
  }

  Future<bool> deleteUser(int id) async {
    try {
      final response = await dio.delete('/users/$id');
      return response.statusCode == 200;
    } catch (e) {
      if (e is DioException) {
        throw Exception('Erro: ${e.message}');
      }
      throw Exception('Erro: $e');
    }
  }
}

import 'package:dio/dio.dart';
import '../models/models.dart';
import 'auth_service.dart';
import 'base_api_service.dart';

class RoleApiService extends BaseApiService {
  RoleApiService(AuthService authService) : super(authService);

  Future<List<Role>> getRoles() async {
    try {
      final response = await dio.get('/roles/');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => Role.fromJson(json)).toList();
      }
      throw Exception('Falha ao carregar roles');
    } catch (e) {
      if (e is DioException) {
        throw Exception('Erro: ${e.message}');
      }
      throw Exception('Erro: $e');
    }
  }

  Future<Role> createRole(RoleCreate role) async {
    try {
      final response = await dio.post('/roles/', data: role.toJson());

      if (response.statusCode == 201) {
        return Role.fromJson(response.data);
      }
      throw Exception('Falha ao criar role');
    } catch (e) {
      if (e is DioException) {
        throw Exception('Erro: ${e.message}');
      }
      throw Exception('Erro: $e');
    }
  }

  Future<Role> updateRole(int id, RoleCreate role) async {
    try {
      final response = await dio.put('/roles/$id', data: role.toJson());

      if (response.statusCode == 200) {
        return Role.fromJson(response.data);
      }
      throw Exception('Falha ao atualizar role');
    } catch (e) {
      if (e is DioException) {
        throw Exception('Erro: ${e.message}');
      }
      throw Exception('Erro: $e');
    }
  }

  Future<bool> deleteRole(int id) async {
    try {
      final response = await dio.delete('/roles/$id');
      return response.statusCode == 200;
    } catch (e) {
      if (e is DioException) {
        throw Exception('Erro: ${e.message}');
      }
      throw Exception('Erro: $e');
    }
  }
}

import '../models/models.dart';
import 'auth_service.dart';
import 'user_api_service.dart';
import 'role_api_service.dart';

class ApiService {
  final AuthService _authService;
  late UserApiService _userApiService;
  late RoleApiService _roleApiService;

  ApiService(this._authService) {
    _userApiService = UserApiService(_authService);
    _roleApiService = RoleApiService(_authService);
  }

  // Métodos para Usuários (delegação para UserApiService)
  Future<List<User>> getUsers() => _userApiService.getUsers();

  Future<User> createUser(UserCreate user) => _userApiService.createUser(user);

  Future<User> updateUser(int id, UserUpdate user) =>
      _userApiService.updateUser(id, user);

  Future<bool> deleteUser(int id) => _userApiService.deleteUser(id);

  // Métodos para Roles (delegação para RoleApiService)
  Future<List<Role>> getRoles() => _roleApiService.getRoles();

  Future<Role> createRole(RoleCreate role) => _roleApiService.createRole(role);

  Future<Role> updateRole(int id, RoleCreate role) =>
      _roleApiService.updateRole(id, role);

  Future<bool> deleteRole(int id) => _roleApiService.deleteRole(id);
}

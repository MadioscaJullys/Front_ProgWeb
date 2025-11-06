import 'package:flutter/foundation.dart';
import 'auth_service.dart';
import 'user_service.dart';
import '../models/models.dart';

// Facade Pattern: ApiFacade fornece uma interface simplificada para operações complexas
// envolvendo autenticação e gerenciamento de usuários, ocultando a complexidade dos serviços subjacentes.
// - Unifica múltiplos serviços em uma única interface
// - Reduz acoplamento entre UI e serviços específicos
// - Facilita manutenção e evolução da API
class ApiFacade extends ChangeNotifier {  // Observer Pattern: Extende ChangeNotifier para notificar mudanças
  final AuthService _authService;  // Dependência: Serviço de autenticação
  final UserService _userService;  // Dependência: Serviço de usuários

  ApiFacade(this._authService, this._userService) {  // Injeção de dependências no construtor
    // Observer Pattern: A facade observa mudanças nos serviços para notificar seus próprios listeners
    _authService.addListener(notifyListeners);  // Registra listener no AuthService
    _userService.addListener(notifyListeners);  // Registra listener no UserService
  }

  // === MÉTODOS DELEGADOS PARA AUTENTICAÇÃO (Facade simplifica acesso) ===
  
  bool get isAuthenticated => _authService.isAuthenticated;  // Propriedade delegada: verifica se usuário está logado
  User? get currentUser => _authService.currentUser;  // Propriedade delegada: obtém usuário atual
  String? get token => _authService.token;  // Propriedade delegada: obtém token JWT

  Future<bool> login(String email, String password) => _authService.login(email, password);  // Método delegada: faz login
  Future<void> logout() => _authService.logout();  // Método delegada: faz logout

  // === MÉTODOS DELEGADOS PARA USUÁRIOS (Facade unifica operações) ===

  Future<List<User>> getUsers() async {  // Facade: Método unificado para buscar todos os usuários
    final token = _authService.token;  // Obtém token do serviço de auth (autorização)
    if (token == null) return [];  // Se não autenticado, retorna lista vazia
    return _userService.getUsers(token);  // Delega operação para UserService
  }

  Future<User?> getUser(int userId) async {  // Facade: Método unificado para buscar usuário por ID
    final token = _authService.token;  // Verifica se tem token válido
    if (token == null) return null;  // Retorna null se não autorizado
    return _userService.getUser(token, userId);  // Delega busca para UserService
  }

  Future<bool> createUser(UserCreate userCreate) async {  // Facade: Método unificado para criar usuário
    final token = _authService.token;  // Verifica permissões através do token
    if (token == null) return false;  // Falha se não tiver autorização
    return _userService.createUser(token, userCreate);  // Delega criação
  }

  Future<bool> updateUser(int userId, UserUpdate userUpdate) async {  // Facade: Método unificado para atualizar
    final token = _authService.token;  // Autorização necessária para modificar
    if (token == null) return false;  // Retorna false se sem permissões
    return _userService.updateUser(token, userId, userUpdate);  // Delega atualização
  }

  Future<bool> deleteUser(int userId) async {  // Facade: Método unificado para deletar usuário
    final token = _authService.token;  // Verifica se usuário tem permissão para deletar
    if (token == null) return false;  // Falha sem autenticação
    return _userService.deleteUser(token, userId);  // Delega deleção
  }
}
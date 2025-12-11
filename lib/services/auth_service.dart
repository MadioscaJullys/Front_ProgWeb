import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../config/config.dart';
import 'dart:convert';

// Strategy Pattern: Define diferentes estratégias de autenticação
// - AuthStrategy: Interface abstrata para diferentes métodos de login
// - OAuth2PasswordStrategy: Estratégia padrão usando OAuth2 password flow
// - AlternativeLoginStrategy: Estratégia alternativa para casos de falha CORS
abstract class AuthStrategy {
  // Interface comum para estratégias
  Future<Map<String, dynamic>> authenticate(
    String email,
    String password,
    Dio dio,
  ); // Método contrato
}

class OAuth2PasswordStrategy implements AuthStrategy {
  // Implementação concreta da estratégia padrão
  @override
  Future<Map<String, dynamic>> authenticate(
    String email,
    String password,
    Dio dio,
  ) async {
    final response = await dio.post(
      // Faz requisição HTTP POST
      '/auth/login', // Endpoint de login
      data: {
        // Dados no formato OAuth2
        'grant_type': 'password', // Tipo de grant
        'username': email, // Email como username
        'password': password, // Senha
      },
      options: Options(
        // Configurações da requisição
        contentType: 'application/x-www-form-urlencoded', // Tipo de conteúdo
        headers: {'Accept': 'application/json'}, // Aceita JSON
      ),
    );
    return response.data; // Retorna dados da resposta
  }
}

class AlternativeLoginStrategy implements AuthStrategy {
  // Estratégia alternativa
  @override
  Future<Map<String, dynamic>> authenticate(
    String email,
    String password,
    Dio dio,
  ) async {
    final response = await dio.post(
      // Requisição alternativa
      '/auth/login',
      data:
          'grant_type=password&username=$email&password=$password', // Formato query string
      options: Options(
        contentType: 'application/x-www-form-urlencoded',
        headers: {'Accept': 'application/json'},
      ),
    );
    return response.data;
  }
}

// Observer Pattern: AuthService implementa o padrão Observer através da extensão de ChangeNotifier,
// permitindo que widgets se inscrevam para notificações de mudanças no estado de autenticação.
// Singleton Pattern: Garante que apenas uma instância do AuthService exista na aplicação.
class AuthService extends ChangeNotifier {
  // ChangeNotifier = Subject no Observer Pattern
  static final AuthService _instance =
      AuthService._internal(); // Instância singleton única
  static final String baseUrl = Config.apiUrl; // Ajuste para seu IP
  static const String _tokenKey = 'auth_token'; // Chave para armazenar token
  static const String _userKey = 'current_user'; // Chave para armazenar usuário

  String? _token; // Estado: token de autenticação
  User? _currentUser; // Estado: usuário atual
  late Dio _dio; // Cliente HTTP
  SharedPreferences? _prefs; // Armazenamento local
  bool _isInitialized = false; // Flag de inicialização
  late AuthStrategy _authStrategy; // Estratégia atual de autenticação

  factory AuthService() {
    // Factory constructor para singleton
    return _instance; // Sempre retorna a mesma instância
  }

  AuthService._internal() {
    // Construtor privado
    _dio = Dio(); // Inicializa cliente HTTP
    _authStrategy = OAuth2PasswordStrategy(); // Define estratégia padrão
    _configureDio(); // Configura cliente HTTP
  }

  /// Inicializa o SharedPreferences e carrega dados salvos
  Future<void> initializeAuth() async {
    if (_isInitialized) return; // Evita reinicializar

    _prefs = await SharedPreferences.getInstance();
    await _loadSavedAuth();
    _isInitialized = true;
  }

  void _configureDio() {
    _dio.options.baseUrl = baseUrl;
    _dio.options.connectTimeout = Config.connectTimeout;
    _dio.options.receiveTimeout = Config.receiveTimeout;
    _dio.options.sendTimeout = Config.connectTimeout;

    // Configurações específicas para web
    if (kIsWeb) {
      _dio.options.headers.addAll({
        'Accept': 'application/json',
        'Content-Type': 'application/x-www-form-urlencoded',
      });

      // Remove headers que podem causar preflight
      _dio.options.headers.remove('Access-Control-Allow-Origin');
      _dio.options.headers.remove('Access-Control-Allow-Methods');
      _dio.options.headers.remove('Access-Control-Allow-Headers');
    }

    // Interceptor para logs e debugging
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          debugPrint('Enviando requisição para: ${options.uri}');
          debugPrint('Headers: ${options.headers}');
          debugPrint('Data: ${options.data}');
          handler.next(options);
        },
        onResponse: (response, handler) {
          debugPrint('Resposta recebida: ${response.statusCode}');
          handler.next(response);
        },
        onError: (error, handler) {
          debugPrint('Erro na requisição: ${error.message}');
          debugPrint('Tipo do erro: ${error.type}');
          if (error.response != null) {
            debugPrint('Status Code: ${error.response!.statusCode}');
            debugPrint('Response data: ${error.response!.data}');
          }
          handler.next(error);
        },
      ),
    );
  }

  bool get isAuthenticated => _token != null;
  User? get currentUser => _currentUser;
  String? get token => _token;

  /// Carrega dados de autenticação salvos no localStorage
  Future<void> _loadSavedAuth() async {
    try {
      if (_prefs == null) return;

      _token = _prefs!.getString(_tokenKey);

      // Carrega dados do usuário se existirem
      final userJson = _prefs!.getString(_userKey);
      if (userJson != null) {
        // TODO: Implementar deserialização do User quando necessário
        // _currentUser = User.fromJson(jsonDecode(userJson));
      }

      if (_token != null) {
        final display = _token!.length > 20
            ? '${_token!.substring(0, 20)}...'
            : _token!;
        debugPrint('Token carregado do cache: $display');
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Erro ao carregar autenticação salva: $e');
      // Se houver erro, limpa os dados corrompidos
      await _clearSavedAuth();
    }
  }

  /// Salva dados de autenticação no localStorage
  Future<void> _saveAuth() async {
    try {
      if (_prefs == null) return;

      if (_token != null) {
        await _prefs!.setString(_tokenKey, _token!);
        debugPrint('Token salvo no cache');
      }

      if (_currentUser != null) {
        // TODO: Implementar serialização do User quando necessário
        // await _prefs!.setString(_userKey, jsonEncode(_currentUser!.toJson()));
        debugPrint('Dados do usuário salvos no cache');
      }
    } catch (e) {
      debugPrint('Erro ao salvar autenticação: $e');
    }
  }

  /// Remove dados de autenticação do localStorage
  Future<void> _clearSavedAuth() async {
    try {
      if (_prefs != null) {
        await _prefs!.remove(_tokenKey);
        await _prefs!.remove(_userKey);
        debugPrint('Cache de autenticação limpo');
      }
    } catch (e) {
      debugPrint('Erro ao limpar cache: $e');
    }
  }

  Future<bool> login(String email, String password) async {
    try {
      // Strategy Pattern: Tenta com a estratégia padrão de autenticação
      final data = await _authStrategy.authenticate(
        email,
        password,
        _dio,
      ); // Executa estratégia atual

      if (data['access_token'] != null) {
        // Se resposta contém token (login OK)
        _token = data['access_token']; // Armazena token no estado
        // Se o backend já retornou dados do usuário no payload de login, utilize-os
        try {
          // Alguns backends encapsulam a resposta em um objeto `data`.
          Map<String, dynamic> payload = {};
          if (data is Map<String, dynamic>) {
            payload = Map<String, dynamic>.from(data);
            if (payload['data'] != null && payload['data'] is Map) {
              payload = Map<String, dynamic>.from(payload['data']);
            }
          }

          if (payload['user'] != null &&
              payload['user'] is Map<String, dynamic>) {
            _currentUser = User.fromJson(
              Map<String, dynamic>.from(payload['user']),
            );
          } else if (payload['profile'] != null &&
              payload['profile'] is Map<String, dynamic>) {
            _currentUser = User.fromJson(
              Map<String, dynamic>.from(payload['profile']),
            );
          }
        } catch (e) {
          debugPrint(
            'Falha ao popular currentUser a partir do payload de login: $e',
          );
        }
        await _saveAuth(); // Persiste token no SharedPreferences
        await _fetchCurrentUser(); // Busca dados completos do usuário
        notifyListeners(); // Observer Pattern: Notifica widgets sobre mudança de autenticação
        return true; // Retorna sucesso
      }
      return false; // Falha: resposta sem token
    } catch (e) {
      debugPrint('Erro no login com estratégia padrão: $e');
      if (e is DioException) {
        // Se erro de rede/HTTP
        debugPrint('Dio Error: ${e.message}');
        debugPrint('Response: ${e.response?.data}');

        // Strategy Pattern: Se erro de CORS/conexão, tenta estratégia alternativa
        if (e.type == DioExceptionType.connectionError ||
            e.message?.contains('CORS') == true) {
          return await _tryAlternativeLogin(
            email,
            password,
          ); // Troca para estratégia alternativa
        }
      }
      return false; // Falha irrecuperável
    }
  }

  Future<bool> _tryAlternativeLogin(String email, String password) async {
    try {
      debugPrint('Tentando login alternativo...');
      _authStrategy =
          AlternativeLoginStrategy(); // Strategy Pattern: Muda para estratégia alternativa

      final data = await _authStrategy.authenticate(
        email,
        password,
        _dio,
      ); // Executa estratégia alternativa

      if (data['access_token'] != null) {
        _token = data['access_token'];
        await _saveAuth();
        await _fetchCurrentUser();
        notifyListeners(); // Observer Pattern: Notifica mudança de estado
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Erro no login alternativo: $e');
      return false;
    } finally {
      _authStrategy =
          OAuth2PasswordStrategy(); // Strategy Pattern: Restaura estratégia padrão
    }
  }

  Future<void> _fetchCurrentUser() async {
    if (_token == null) return;

    try {
      // Tentar buscar usuário usando a API de usuários
      // Para isso, vamos precisar do ID do usuário ou buscar pelo token
      // Por enquanto, vamos simular com o primeiro usuário admin para teste
      await _tryFetchUserFromAPI();
    } catch (e) {
      debugPrint('Erro ao buscar usuário atual: $e');
    }
  }

  Future<void> _tryFetchUserFromAPI() async {
    try {
      // Tenta extrair informações do token (se for JWT) para popular currentUser
      if (_token == null) {
        _currentUser = null;
        return;
      }

      final parts = _token!.split('.');
      if (parts.length != 3) {
        // Não é um JWT: não conseguimos extrair payload
        _currentUser = null;
        return;
      }

      final payload = parts[1];
      // Ajuste do padding Base64Url
      String normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final Map<String, dynamic> map = jsonDecode(decoded);

      // Procurar claims comuns para role
      int? roleId;
      String? roleName;

      if (map.containsKey('role_id')) {
        roleId = (map['role_id'] is int)
            ? map['role_id']
            : int.tryParse('${map['role_id']}');
      }
      if (map.containsKey('role')) {
        final r = map['role'];
        if (r is Map && r.containsKey('id')) {
          roleId = (r['id'] is int) ? r['id'] : int.tryParse('${r['id']}');
        }
        if (r is String) roleName = r;
      }
      if (map.containsKey('roles')) {
        // às vezes vem como lista
        final r = map['roles'];
        if (r is List && r.isNotEmpty) {
          final first = r.first;
          if (first is Map && first.containsKey('id')) {
            roleId = (first['id'] is int)
                ? first['id']
                : int.tryParse('${first['id']}');
          }
          if (first is String) roleName = first;
        }
      }

      if (map.containsKey('role_name')) roleName = '${map['role_name']}';
      if (map.containsKey('email')) {
        // Monta um usuário mínimo com as claims encontradas
        final email = '${map['email']}';
        final role = Role(
          id: roleId ?? 2,
          name: roleName ?? (roleId == 1 ? 'admin' : 'user'),
        );
        _currentUser = User(
          id: map['sub'] is int
              ? map['sub']
              : (map['user_id'] is int ? map['user_id'] : 0),
          email: email,
          fullName: null,
          profileImageUrl: null,
          profileImageBase64: null,
          role: role,
        );
        return;
      }

      // Se não encontramos email, mas detectamos roleId/roleName, criamos usuário mínimo
      if (roleId != null || roleName != null) {
        final role = Role(
          id: roleId ?? 2,
          name: roleName ?? (roleId == 1 ? 'admin' : 'user'),
        );
        _currentUser = User(
          id: 0,
          email: 'unknown',
          fullName: null,
          profileImageUrl: null,
          profileImageBase64: null,
          role: role,
        );
        return;
      }

      _currentUser = null;
    } catch (e) {
      debugPrint('Erro ao buscar usuário da API: $e');
      _currentUser = null;
    }
  }

  // Método para definir o usuário atual externamente
  void setCurrentUser(User? user) {
    _currentUser = user;
    notifyListeners();
  }

  Future<void> logout() async {
    _token = null;
    _currentUser = null;

    // Remove dados do localStorage
    await _clearSavedAuth();

    notifyListeners();
  }

  Map<String, String> get authHeaders {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }
}

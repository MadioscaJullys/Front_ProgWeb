import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

// Strategy Pattern: Define diferentes estratégias de autenticação
// - AuthStrategy: Interface abstrata para diferentes métodos de login
// - OAuth2PasswordStrategy: Estratégia padrão usando OAuth2 password flow
// - AlternativeLoginStrategy: Estratégia alternativa para casos de falha CORS
abstract class AuthStrategy {  // Interface comum para estratégias
  Future<Map<String, dynamic>> authenticate(String email, String password, Dio dio);  // Método contrato
}

class OAuth2PasswordStrategy implements AuthStrategy {  // Implementação concreta da estratégia padrão
  @override
  Future<Map<String, dynamic>> authenticate(String email, String password, Dio dio) async {
    final response = await dio.post(  // Faz requisição HTTP POST
      '/auth/login',  // Endpoint de login
      data: {  // Dados no formato OAuth2
        'grant_type': 'password',  // Tipo de grant
        'username': email,  // Email como username
        'password': password,  // Senha
      },
      options: Options(  // Configurações da requisição
        contentType: 'application/x-www-form-urlencoded',  // Tipo de conteúdo
        headers: {'Accept': 'application/json'},  // Aceita JSON
      ),
    );
    return response.data;  // Retorna dados da resposta
  }
}

class AlternativeLoginStrategy implements AuthStrategy {  // Estratégia alternativa
  @override
  Future<Map<String, dynamic>> authenticate(String email, String password, Dio dio) async {
    final response = await dio.post(  // Requisição alternativa
      '/auth/login',
      data: 'grant_type=password&username=$email&password=$password',  // Formato query string
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
class AuthService extends ChangeNotifier {  // ChangeNotifier = Subject no Observer Pattern
  static final AuthService _instance = AuthService._internal();  // Instância singleton única
  static const String baseUrl = Config.apiUrl; // Ajuste para seu IP
  static const String _tokenKey = 'auth_token';  // Chave para armazenar token
  static const String _userKey = 'current_user';  // Chave para armazenar usuário

  String? _token;  // Estado: token de autenticação
  User? _currentUser;  // Estado: usuário atual
  late Dio _dio;  // Cliente HTTP
  SharedPreferences? _prefs;  // Armazenamento local
  bool _isInitialized = false;  // Flag de inicialização
  late AuthStrategy _authStrategy;  // Estratégia atual de autenticação

  factory AuthService() {  // Factory constructor para singleton
    return _instance;  // Sempre retorna a mesma instância
  }

  AuthService._internal() {  // Construtor privado
    _dio = Dio();  // Inicializa cliente HTTP
    _authStrategy = OAuth2PasswordStrategy();  // Define estratégia padrão
    _configureDio();  // Configura cliente HTTP
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
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
    _dio.options.sendTimeout = const Duration(seconds: 30);

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
          print('Enviando requisição para: ${options.uri}');
          print('Headers: ${options.headers}');
          print('Data: ${options.data}');
          handler.next(options);
        },
        onResponse: (response, handler) {
          print('Resposta recebida: ${response.statusCode}');
          handler.next(response);
        },
        onError: (error, handler) {
          print('Erro na requisição: ${error.message}');
          print('Tipo do erro: ${error.type}');
          if (error.response != null) {
            print('Status Code: ${error.response!.statusCode}');
            print('Response data: ${error.response!.data}');
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
        print('Token carregado do cache: ${_token!.substring(0, 20)}...');
        notifyListeners();
      }
    } catch (e) {
      print('Erro ao carregar autenticação salva: $e');
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
        print('Token salvo no cache');
      }

      if (_currentUser != null) {
        // TODO: Implementar serialização do User quando necessário
        // await _prefs!.setString(_userKey, jsonEncode(_currentUser!.toJson()));
        print('Dados do usuário salvos no cache');
      }
    } catch (e) {
      print('Erro ao salvar autenticação: $e');
    }
  }

  /// Remove dados de autenticação do localStorage
  Future<void> _clearSavedAuth() async {
    try {
      if (_prefs != null) {
        await _prefs!.remove(_tokenKey);
        await _prefs!.remove(_userKey);
        print('Cache de autenticação limpo');
      }
    } catch (e) {
      print('Erro ao limpar cache: $e');
    }
  }

  Future<bool> login(String email, String password) async {
    try {
      // Strategy Pattern: Tenta com a estratégia padrão de autenticação
      final data = await _authStrategy.authenticate(email, password, _dio);  // Executa estratégia atual

      if (data['access_token'] != null) {  // Se resposta contém token (login OK)
        _token = data['access_token'];  // Armazena token no estado
        await _saveAuth();  // Persiste token no SharedPreferences
        await _fetchCurrentUser();  // Busca dados completos do usuário
        notifyListeners();  // Observer Pattern: Notifica widgets sobre mudança de autenticação
        return true;  // Retorna sucesso
      }
      return false;  // Falha: resposta sem token
    } catch (e) {
      print('Erro no login com estratégia padrão: $e');
      if (e is DioException) {  // Se erro de rede/HTTP
        print('Dio Error: ${e.message}');
        print('Response: ${e.response?.data}');

        // Strategy Pattern: Se erro de CORS/conexão, tenta estratégia alternativa
        if (e.type == DioExceptionType.connectionError ||
            e.message?.contains('CORS') == true) {
          return await _tryAlternativeLogin(email, password);  // Troca para estratégia alternativa
        }
      }
      return false;  // Falha irrecuperável
    }
  }

  Future<bool> _tryAlternativeLogin(String email, String password) async {
    try {
      print('Tentando login alternativo...');
      _authStrategy = AlternativeLoginStrategy(); // Strategy Pattern: Muda para estratégia alternativa
      
      final data = await _authStrategy.authenticate(email, password, _dio);  // Executa estratégia alternativa

      if (data['access_token'] != null) {
        _token = data['access_token'];
        await _saveAuth();
        await _fetchCurrentUser();
        notifyListeners();  // Observer Pattern: Notifica mudança de estado
        return true;
      }
      return false;
    } catch (e) {
      print('Erro no login alternativo: $e');
      return false;
    } finally {
      _authStrategy = OAuth2PasswordStrategy(); // Strategy Pattern: Restaura estratégia padrão
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
      print('Erro ao buscar usuário atual: $e');
    }
  }

  Future<void> _tryFetchUserFromAPI() async {
    try {
      // Para buscar usuário atual, usaremos uma instância externa do ApiService
      // Por enquanto, deixaremos como null até implementar endpoint /me
      _currentUser = null;
    } catch (e) {
      print('Erro ao buscar usuário da API: $e');
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
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $_token',
    };
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'services/user_service.dart';
import 'services/api_facade.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'config/config.dart';
import 'widgets/environment_banner.dart';

// Provider Pattern: Usa o Provider para gerenciar o estado global da aplicação,
// implementando o padrão Observer para notificar widgets sobre mudanças no AuthService.
void main() {
  // Imprime a URL da API sendo usada no console
  debugPrint('🚀 App iniciado');
  debugPrint('🌐 API URL: ${Config.apiUrl}');
  debugPrint('📦 Versão: ${Config.appVersion}');
  debugPrint('🔧 Modo: ${Config.apiUrl.contains('localhost') ? 'DESENVOLVIMENTO' : 'PRODUÇÃO'}');
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(  // Provider Pattern: Container para múltiplos providers de estado
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),  // Provider para AuthService (Observer Pattern)
        ChangeNotifierProvider(create: (_) => UserService()),  // Provider para UserService
        ChangeNotifierProxyProvider2<AuthService, UserService, ApiFacade>(  // Facade Pattern: Provider para facade
          create: (context) => ApiFacade(  // Cria instância da facade
            Provider.of<AuthService>(context, listen: false),  // Injeta AuthService na facade
            Provider.of<UserService>(context, listen: false),  // Injeta UserService na facade
          ),
          update: (context, auth, user, previous) => previous ?? ApiFacade(auth, user),  // Atualiza facade quando dependências mudam
        ),
      ],
      child: EnvironmentBanner(  // Widget filho que terá acesso aos providers acima
        child: MaterialApp(  // App principal Flutter
          title: 'Admin App',
          theme: ThemeData(  // Tema da aplicação
            primarySwatch: Colors.blue,
            visualDensity: VisualDensity.adaptivePlatformDensity,
          ),
          home: AuthWrapper(),  // Tela inicial (verifica autenticação)
          debugShowCheckedModeBanner: false,  // Remove banner de debug
        ),
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  @override
  _AuthWrapperState createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    await authService.initializeAuth();

    if (mounted) {
      setState(() {
        _isInitializing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Carregando...'),
            ],
          ),
        ),
      );
    }

    return Consumer<ApiFacade>(
      builder: (context, apiFacade, child) {
        if (apiFacade.isAuthenticated) {
          return DashboardScreen();
        } else {
          return LoginScreen();
        }
      },
    );
  }
}

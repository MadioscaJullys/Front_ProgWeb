import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'services/user_service.dart';
import 'services/api_service.dart';
import 'services/api_facade.dart';
import 'screens/register_screen.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/users_screen.dart';
import 'screens/user_detail_screen.dart';
import 'screens/roles_screen.dart';
import 'screens/feed_screen.dart';
import 'screens/create_post_screen.dart';
import 'config/config.dart';
// import 'widgets/environment_banner.dart'; // not used
import 'services/posts_api_service.dart';
import 'models/models.dart';

// Provider Pattern: Usa o Provider para gerenciar o estado global da aplicação,
// implementando o padrão Observer para notificar widgets sobre mudanças no AuthService.
void main() {
  // Imprime a URL da API sendo usada no console
  debugPrint('🚀 App iniciado');
  debugPrint('🌐 API URL: ${Config.apiUrl}');
  debugPrint('📦 Versão: ${Config.appVersion}');
  debugPrint(
    '🔧 Modo: ${Config.apiUrl.contains('localhost') ? 'DESENVOLVIMENTO' : 'PRODUÇÃO'}',
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      // Provider Pattern: Container para múltiplos providers de estado
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthService(),
        ), // Provider para AuthService (Observer Pattern)
        ChangeNotifierProvider(
          create: (_) => UserService(),
        ), // Provider para UserService
        ProxyProvider<AuthService, ApiService>(
          update: (context, auth, previous) => ApiService(auth),
        ),
        ProxyProvider<AuthService, PostsService>(
          update: (context, auth, previous) => previous ?? PostsService(auth),
        ),
        ChangeNotifierProxyProvider2<AuthService, UserService, ApiFacade>(
          // Facade Pattern: Provider para facade
          create: (context) => ApiFacade(
            // Cria instância da facade
            Provider.of<AuthService>(
              context,
              listen: false,
            ), // Injeta AuthService
            Provider.of<UserService>(
              context,
              listen: false,
            ), // Injeta UserService
            Provider.of<PostsService>(
              context,
              listen: false,
            ), // Injeta PostsApiService
          ),
          update: (context, auth, user, previous) =>
              previous ??
              ApiFacade(
                auth,
                user,
                Provider.of<PostsService>(context, listen: false),
              ), // Atualiza facade quando dependências mudam
        ),
      ],
      child: MaterialApp(
        title: 'API',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),

        debugShowCheckedModeBanner: false,

        routes: {
          '/login': (context) => LoginScreen(),
          '/dashboard': (context) => DashboardScreen(),
          '/users': (context) => UsersScreen(
            apiService: Provider.of<ApiService>(context, listen: false),
          ),
          '/user-detail': (context) {
            final args = ModalRoute.of(context)!.settings.arguments;
            if (args is User) {
              return UserDetailScreen(user: args);
            }
            return Scaffold(
              appBar: AppBar(title: Text('Usuário não fornecido')),
              body: Center(
                child: Text('Nenhum usuário foi passado para a rota.'),
              ),
            );
          },
          '/roles': (context) => RolesScreen(
            apiService: Provider.of<ApiService>(context, listen: false),
          ),
          "/feed": (context) => FeedScreen(),
          "/create-post": (context) => CreatePostScreen(),
          "/register": (context) => RegisterScreen(),
        },

        home: AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({Key? key}) : super(key: key);

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
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Consumer<AuthService>(
      builder: (context, auth, child) {
        if (!auth.isAuthenticated) {
          return LoginScreen();
        }

        // Aqui decidimos a tela conforme a role
        final roleName = auth.currentUser?.role.name;
        if (roleName == "admin") {
          return DashboardScreen(); // tela admin
        } else {
          return FeedScreen(); // criar essa tela / feed
        }
      },
    );
  }
}

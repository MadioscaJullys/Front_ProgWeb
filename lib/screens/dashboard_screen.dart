import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../widgets/user_avatar.dart';
import 'users_screen.dart';
import 'roles_screen.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  late List<Widget> _screens;
  late ApiService _apiService;

  @override
  void initState() {
    super.initState();
    final authService = Provider.of<AuthService>(context, listen: false);
    _apiService = ApiService(authService);
    _screens = [
      _DashboardHome(
        apiService: _apiService,
        onNavigate: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
      UsersScreen(apiService: _apiService),
      RolesScreen(apiService: _apiService),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Dashboard'),
        actions: [
          Consumer<AuthService>(
            builder: (context, authService, child) {
              final currentUser = authService.currentUser;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (currentUser != null) ...[
                    Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            currentUser.fullName ?? 'Usuário',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            currentUser.role.name,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      child: Container(
                        padding: EdgeInsets.all(4),
                        child: UserAvatar(
                          profileImageUrl: currentUser.profileImageUrl,
                          profileImageBase64: currentUser.profileImageBase64,
                          fallbackText: currentUser.fullName?.isNotEmpty == true
                              ? currentUser.fullName![0].toUpperCase()
                              : 'U',
                          size: 36,
                        ),
                      ),
                      onSelected: (value) async {
                        if (value == 'logout') {
                          await authService.logout();
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'profile',
                          child: Row(
                            children: [
                              Icon(Icons.person, size: 18),
                              SizedBox(width: 8),
                              Text('Perfil'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'logout',
                          child: Row(
                            children: [
                              Icon(Icons.logout, size: 18),
                              SizedBox(width: 8),
                              Text('Sair'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ] else
                    IconButton(
                      icon: Icon(Icons.logout),
                      onPressed: () async => await authService.logout(),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            labelType: NavigationRailLabelType.all,
            destinations: [
              NavigationRailDestination(
                icon: Icon(Icons.dashboard),
                label: Text('Dashboard'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.people),
                label: Text('Usuários'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.security),
                label: Text('Roles'),
              ),
            ],
          ),
          VerticalDivider(thickness: 1, width: 1),
          Expanded(child: _screens[_selectedIndex]),
        ],
      ),
    );
  }
}

class _DashboardHome extends StatefulWidget {
  final ApiService apiService;
  final Function(int) onNavigate;

  const _DashboardHome({required this.apiService, required this.onNavigate});

  @override
  _DashboardHomeState createState() => _DashboardHomeState();
}

class _DashboardHomeState extends State<_DashboardHome> {
  int usersCount = 0;
  int rolesCount = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCounts();
  }

  Future<void> _loadCounts() async {
    try {
      final users = await widget.apiService.getUsers();
      final roles = await widget.apiService.getRoles();

      setState(() {
        usersCount = users.length;
        rolesCount = roles.length;
        isLoading = false;
      });
    } catch (e) {
      print('Erro ao carregar contadores: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bem-vindo ao Dashboard',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          SizedBox(height: 24),
          if (isLoading)
            Center(child: CircularProgressIndicator())
          else
            Expanded(
              child: GridView.count(
                crossAxisCount: 3,
                childAspectRatio: 1.2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                children: [
                  _DashboardCard(
                    title: 'Usuários',
                    subtitle: '$usersCount usuários cadastrados',
                    icon: Icons.people,
                    color: Colors.blue,
                    onTap: () => widget.onNavigate(1),
                  ),
                  _DashboardCard(
                    title: 'Roles',
                    subtitle: '$rolesCount roles configuradas',
                    icon: Icons.security,
                    color: Colors.green,
                    onTap: () => widget.onNavigate(2),
                  ),
                  _DashboardCard(
                    title: 'Relatórios',
                    subtitle: 'Visualizar estatísticas',
                    icon: Icons.analytics,
                    color: Colors.orange,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Funcionalidade em desenvolvimento'),
                        ),
                      );
                    },
                  ),
                  _DashboardCard(
                    title: 'Configurações',
                    subtitle: 'Configurações do sistema',
                    icon: Icons.settings,
                    color: Colors.purple,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Funcionalidade em desenvolvimento'),
                        ),
                      );
                    },
                  ),
                  _DashboardCard(
                    title: 'Logs',
                    subtitle: 'Visualizar logs do sistema',
                    icon: Icons.list_alt,
                    color: Colors.red,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Funcionalidade em desenvolvimento'),
                        ),
                      );
                    },
                  ),
                  _DashboardCard(
                    title: 'Backup',
                    subtitle: 'Gerenciar backups',
                    icon: Icons.backup,
                    color: Colors.teal,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Funcionalidade em desenvolvimento'),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _DashboardCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: color),
              SizedBox(height: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

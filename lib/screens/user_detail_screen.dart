import 'package:flutter/material.dart';
import '../models/models.dart';
import '../widgets/user_avatar.dart';

class UserDetailScreen extends StatelessWidget {
  final User user;

  const UserDetailScreen({Key? key, required this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detalhes do Usuário'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Avatar grande no topo
            Center(
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      spreadRadius: 2,
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: UserAvatar(
                  profileImageUrl: user.profileImageUrl,
                  profileImageBase64: user.profileImageBase64,
                  fallbackText: user.fullName?.isNotEmpty == true
                      ? user.fullName![0].toUpperCase()
                      : user.email[0].toUpperCase(),
                  size: 120,
                  backgroundColor: Colors.blue[100],
                ),
              ),
            ),
            SizedBox(height: 24),

            // Nome do usuário
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Informações Pessoais',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                    SizedBox(height: 16),

                    _buildInfoRow(
                      context,
                      'Nome Completo',
                      user.fullName ?? 'Não informado',
                      Icons.person,
                    ),

                    _buildInfoRow(context, 'Email', user.email, Icons.email),

                    _buildInfoRow(
                      context,
                      'ID do Usuário',
                      '#${user.id}',
                      Icons.badge,
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            // Informações da Role
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Permissões e Acesso',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                    SizedBox(height: 16),

                    _buildInfoRow(
                      context,
                      'Função (Role)',
                      user.role.name,
                      Icons.security,
                    ),

                    _buildInfoRow(
                      context,
                      'ID da Função',
                      '#${user.role.id}',
                      Icons.key,
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            SizedBox(height: 32),

            // Botões de ação
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  icon: Icon(Icons.edit),
                  label: Text('Editar'),
                  onPressed: () {
                    Navigator.of(context).pop('edit');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),

                SizedBox(width: 16),

                OutlinedButton.icon(
                  icon: Icon(Icons.arrow_back),
                  label: Text('Voltar'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value,
    IconData icon, {
    bool isUrl = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 2),
                isUrl
                    ? Text(
                        value,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blue[700],
                          decoration: TextDecoration.underline,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      )
                    : Text(
                        value,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import '../models/models.dart';
import '../services/api_service.dart';
import '../widgets/user_avatar.dart';
import 'user_detail_screen.dart';

class UsersScreen extends StatefulWidget {
  final ApiService apiService;

  const UsersScreen({Key? key, required this.apiService}) : super(key: key);

  @override
  _UsersScreenState createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  List<User> users = [];
  List<Role> roles = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      isLoading = true;
    });

    try {
      final [loadedUsers, loadedRoles] = await Future.wait([
        widget.apiService.getUsers(),
        widget.apiService.getRoles(),
      ]);

      setState(() {
        users = loadedUsers as List<User>;
        roles = loadedRoles as List<Role>;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao carregar dados: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Gerenciar Usuários',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                ElevatedButton.icon(
                  icon: Icon(Icons.add),
                  label: Text('Novo Usuário'),
                  onPressed: () => _showUserDialog(),
                ),
              ],
            ),
          ),
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : users.isEmpty
                ? Center(child: Text('Nenhum usuário encontrado'))
                : ListView.builder(
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final user = users[index];
                      return Card(
                        margin: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        child: ListTile(
                          leading: UserAvatar(
                            profileImageUrl: user.profileImageUrl,
                            profileImageBase64: user.profileImageBase64,
                            fallbackText: user.fullName ?? user.email,
                            size: 40,
                          ),
                          title: Text(user.fullName ?? user.email),
                          subtitle: Text('${user.email} - ${user.role.name}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.visibility),
                                onPressed: () => _viewUserDetails(user),
                                tooltip: 'Ver detalhes',
                              ),
                              IconButton(
                                icon: Icon(Icons.edit),
                                onPressed: () => _showUserDialog(user: user),
                                tooltip: 'Editar',
                              ),
                              IconButton(
                                icon: Icon(Icons.delete),
                                onPressed: () => _deleteUser(user),
                                tooltip: 'Excluir',
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _viewUserDetails(User user) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => UserDetailScreen(user: user)),
    );

    // Se o usuário clicou em editar na tela de detalhes
    if (result == 'edit') {
      _showUserDialog(user: user);
    }
  }

  void _showUserDialog({User? user}) {
    showDialog(
      context: context,
      builder: (context) => UserDialog(
        user: user,
        roles: roles,
        onSave: (userData) async {
          if (user == null) {
            // Criar novo usuário
            await widget.apiService.createUser(userData);
          } else {
            // Atualizar usuário existente
            await widget.apiService.updateUser(
              user.id,
              UserUpdate(
                email: userData.email,
                fullName: userData.fullName,
                profileImageUrl: userData.profileImageUrl,
                profileImageBase64: userData.profileImageBase64,
                roleId: userData.roleId,
              ),
            );
          }
          _loadData();
        },
      ),
    );
  }

  Future<void> _deleteUser(User user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmar exclusão'),
        content: Text('Deseja realmente excluir o usuário ${user.email}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await widget.apiService.deleteUser(user.id);
      _loadData();
    }
  }
}

class UserDialog extends StatefulWidget {
  final User? user;
  final List<Role> roles;
  final Function(UserCreate) onSave;

  const UserDialog({
    Key? key,
    this.user,
    required this.roles,
    required this.onSave,
  }) : super(key: key);

  @override
  _UserDialogState createState() => _UserDialogState();
}

class _UserDialogState extends State<UserDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late TextEditingController _fullNameController;
  late TextEditingController _imageUrlController;
  Role? _selectedRole;
  String? _selectedImageBase64;
  String? _selectedImageName;
  bool _useImageFile = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.user?.email ?? '');
    _passwordController = TextEditingController();
    _fullNameController = TextEditingController(
      text: widget.user?.fullName ?? '',
    );
    _imageUrlController = TextEditingController(
      text: widget.user?.profileImageUrl ?? '',
    );

    if (widget.user != null) {
      _selectedRole = widget.roles.firstWhere(
        (role) => role.id == widget.user!.role.id,
        orElse: () => widget.roles.first,
      );
    } else {
      _selectedRole = widget.roles.isNotEmpty ? widget.roles.first : null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.user == null ? 'Novo Usuário' : 'Editar Usuário'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(labelText: 'Email'),
                validator: (value) =>
                    value?.isEmpty == true ? 'Campo obrigatório' : null,
              ),
              if (widget.user == null)
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(labelText: 'Senha'),
                  obscureText: true,
                  validator: (value) =>
                      value?.isEmpty == true ? 'Campo obrigatório' : null,
                ),
              TextFormField(
                controller: _fullNameController,
                decoration: InputDecoration(labelText: 'Nome Completo'),
              ),
              // Seleção de tipo de imagem
              Row(
                children: [
                  Radio<bool>(
                    value: false,
                    groupValue: _useImageFile,
                    onChanged: (value) {
                      setState(() {
                        _useImageFile = value!;
                        _selectedImageBase64 = null;
                        _selectedImageName = null;
                      });
                    },
                  ),
                  Text('URL da Imagem'),
                  SizedBox(width: 20),
                  Radio<bool>(
                    value: true,
                    groupValue: _useImageFile,
                    onChanged: (value) {
                      setState(() {
                        _useImageFile = value!;
                        _imageUrlController.clear();
                      });
                    },
                  ),
                  Text('Upload de Arquivo'),
                ],
              ),
              SizedBox(height: 8),
              if (!_useImageFile)
                TextFormField(
                  controller: _imageUrlController,
                  decoration: InputDecoration(labelText: 'URL da Imagem'),
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ElevatedButton.icon(
                          icon: Icon(Icons.upload_file),
                          label: Text('Selecionar Imagem'),
                          onPressed: _pickImage,
                        ),
                        SizedBox(width: 10),
                        if (_selectedImageName != null)
                          Expanded(
                            child: Text(
                              _selectedImageName!,
                              style: TextStyle(fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                    if (_selectedImageBase64 != null)
                      Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          'Imagem carregada (${(_selectedImageBase64!.length / 1024).round()} KB)',
                          style: TextStyle(fontSize: 12, color: Colors.green),
                        ),
                      ),
                  ],
                ),
              SizedBox(height: 16),
              DropdownButtonFormField<Role>(
                value: _selectedRole,
                decoration: InputDecoration(labelText: 'Role'),
                items: widget.roles.map((role) {
                  return DropdownMenuItem(value: role, child: Text(role.name));
                }).toList(),
                onChanged: (role) {
                  setState(() {
                    _selectedRole = role;
                  });
                },
                validator: (value) =>
                    value == null ? 'Campo obrigatório' : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancelar'),
        ),
        ElevatedButton(onPressed: _save, child: Text('Salvar')),
      ],
    );
  }

  Future<void> _pickImage() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final bytes = file.bytes;

        if (bytes != null) {
          // Determina o tipo MIME baseado na extensão do arquivo
          String mimeType = _getMimeTypeFromExtension(
            file.extension?.toLowerCase() ?? '',
          );

          // Para formatos não suportados pelo Flutter, fazemos simulação de conversão
          if (mimeType == 'image/avif' ||
              mimeType == 'image/heif' ||
              mimeType == 'image/heic') {
            // Simula conversão do backend: informa que seria convertido para JPEG
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('🔄 Formato $mimeType detectado'),
                    Text('📝 Simular: Backend converteria para JPEG'),
                    Text(
                      '⚠️  Flutter não renderiza ${mimeType.split('/')[1].toUpperCase()} nativamente',
                    ),
                  ],
                ),
                backgroundColor: Colors.blue[700],
                duration: Duration(seconds: 6),
              ),
            );

            // Simula que o backend converteria para JPEG
            // (Na realidade, o backend faria isso com bibliotecas como PIL/Pillow)
            mimeType = 'image/jpeg';
          }

          // Cria o base64 com cabeçalho de tipo MIME
          String base64String = base64Encode(bytes);
          String dataUrl = 'data:$mimeType;base64,$base64String';

          setState(() {
            _selectedImageBase64 = dataUrl;
            _selectedImageName = file.name;
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao selecionar imagem: $e')));
    }
  }

  /// Determina o tipo MIME baseado na extensão do arquivo
  String _getMimeTypeFromExtension(String extension) {
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      case 'bmp':
        return 'image/bmp';
      case 'avif':
        return 'image/avif';
      case 'heic':
      case 'heif':
        return 'image/heif';
      default:
        return 'image/jpeg'; // Default para JPEG
    }
  }

  void _save() {
    if (_formKey.currentState!.validate() && _selectedRole != null) {
      final userData = UserCreate(
        email: _emailController.text,
        password: _passwordController.text.isNotEmpty
            ? _passwordController.text
            : 'defaultpass123',
        fullName: _fullNameController.text.isNotEmpty
            ? _fullNameController.text
            : null,
        profileImageUrl: !_useImageFile && _imageUrlController.text.isNotEmpty
            ? _imageUrlController.text
            : null,
        profileImageBase64: _useImageFile ? _selectedImageBase64 : null,
        roleId: _selectedRole!.id,
      );

      widget.onSave(userData);
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }
}

import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class RolesScreen extends StatefulWidget {
  final ApiService apiService;

  const RolesScreen({Key? key, required this.apiService}) : super(key: key);

  @override
  _RolesScreenState createState() => _RolesScreenState();
}

class _RolesScreenState extends State<RolesScreen> {
  List<Role> roles = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRoles();
  }

  Future<void> _loadRoles() async {
    setState(() {
      isLoading = true;
    });

    try {
      final loadedRoles = await widget.apiService.getRoles();
      setState(() {
        roles = loadedRoles;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao carregar roles: $e')));
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
                  'Gerenciar Roles',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                ElevatedButton.icon(
                  icon: Icon(Icons.add),
                  label: Text('Nova Role'),
                  onPressed: () => _showRoleDialog(),
                ),
              ],
            ),
          ),
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : roles.isEmpty
                ? Center(child: Text('Nenhuma role encontrada'))
                : ListView.builder(
                    itemCount: roles.length,
                    itemBuilder: (context, index) {
                      final role = roles[index];
                      return Card(
                        margin: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.green,
                            child: Icon(Icons.security, color: Colors.white),
                          ),
                          title: Text(role.name),
                          subtitle: Text('ID: ${role.id}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.edit),
                                onPressed: () => _showRoleDialog(role: role),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete),
                                onPressed: () => _deleteRole(role),
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

  void _showRoleDialog({Role? role}) {
    showDialog(
      context: context,
      builder: (context) => RoleDialog(
        role: role,
        onSave: (roleData) async {
          if (role == null) {
            // Criar nova role
            await widget.apiService.createRole(roleData);
          } else {
            // Atualizar role existente
            await widget.apiService.updateRole(role.id, roleData);
          }
          _loadRoles();
        },
      ),
    );
  }

  Future<void> _deleteRole(Role role) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmar exclusão'),
        content: Text('Deseja realmente excluir a role "${role.name}"?'),
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
      try {
        await widget.apiService.deleteRole(role.id);
        _loadRoles();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Role "${role.name}" excluída com sucesso')),
        );
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao excluir role: $e')));
      }
    }
  }
}

class RoleDialog extends StatefulWidget {
  final Role? role;
  final Function(RoleCreate) onSave;

  const RoleDialog({Key? key, this.role, required this.onSave})
    : super(key: key);

  @override
  _RoleDialogState createState() => _RoleDialogState();
}

class _RoleDialogState extends State<RoleDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.role?.name ?? '');
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.role == null ? 'Nova Role' : 'Editar Role'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _nameController,
          decoration: InputDecoration(labelText: 'Nome da Role'),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Campo obrigatório';
            }
            return null;
          },
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

  void _save() {
    if (_formKey.currentState!.validate()) {
      final roleData = RoleCreate(name: _nameController.text);
      widget.onSave(roleData);
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
}

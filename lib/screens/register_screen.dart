import 'package:flutter/material.dart';
import '../services/register_service.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _roleId = TextEditingController();

  bool loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Criar Conta")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _username,
              decoration: InputDecoration(labelText: "Usuário"),
            ),
            TextField(
              controller: _email,
              decoration: InputDecoration(labelText: "Email"),
            ),
            TextField(
              controller: _password,
              obscureText: true,
              decoration: InputDecoration(labelText: "Senha"),
            ),
            SizedBox(height: 8),
            TextField(
              controller: _roleId,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: "Role ID (numérico)"),
            ),
            SizedBox(height: 20),
            loading
                ? CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: () async {
                      setState(() => loading = true);

                      final result = await RegisterService().register(
                        username: _username.text.trim(),
                        email: _email.text.trim(),
                        password: _password.text.trim(),
                        roleId: int.parse(_roleId.text.trim()),
                      );

                      if (!mounted) return;

                      setState(() => loading = false);

                      if (result["success"]) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Conta criada com sucesso!")),
                        );
                        Navigator.pop(context);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Erro: ${result["error"]}")),
                        );
                      }
                    },
                    child: Text("Cadastrar"),
                  ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _username.dispose();
    _email.dispose();
    _password.dispose();
    _roleId.dispose();
    super.dispose();
  }
}

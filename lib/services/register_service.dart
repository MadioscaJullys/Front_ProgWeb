import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/config.dart';

class RegisterService {
  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    required int roleId,
  }) async {
    final url = Uri.parse('${Config.apiUrl}/users');

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "username": username,
        "email": email,
        "password": password,
        "role_id": roleId,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return {"success": true};
    } else {
      return {"success": false, "error": response.body};
    }
  }
}

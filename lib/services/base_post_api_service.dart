import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/config.dart';

class BasePostApiService {
  final String baseUrl = Config.apiUrl;

  Future<dynamic> get(String endpoint, {String? token}) async {
    final uri = Uri.parse("$baseUrl$endpoint");

    // Diagnostic logging
    try {
      debugPrint('--> GET $uri');
      final headerPreview = StringBuffer();
      if (token != null) {
        headerPreview.write('Authorization: Bearer <present>, ');
      } else {
        headerPreview.write('Authorization: <omitted>, ');
      }
      headerPreview.write('Content-Type: application/json');
      debugPrint('Headers: {$headerPreview}');
    } catch (_) {}

    final headers = <String, String>{"Content-Type": "application/json"};
    if (token != null) headers["Authorization"] = "Bearer $token";

    final response = await http.get(uri, headers: headers);

    try {
      debugPrint('<-- GET ${response.statusCode} $uri');
      debugPrint('Response body: ${response.body}');
    } catch (_) {}

    return _processResponse(response);
  }

  Future<dynamic> post(
    String endpoint,
    Map<String, dynamic> body, {
    String? token,
  }) async {
    final response = await http.post(
      Uri.parse("$baseUrl$endpoint"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode(body),
    );

    return _processResponse(response);
  }

  Future<dynamic> uploadMultipart({
    required String endpoint,
    required Map<String, String> fields,
    required Uint8List fileBytes,
    required String filename,
    String? token,
  }) async {
    var request = http.MultipartRequest("POST", Uri.parse("$baseUrl$endpoint"));

    request.headers["Authorization"] = "Bearer $token";

    // campos normais
    fields.forEach((key, value) {
      request.fields[key] = value;
    });

    // arquivo
    request.files.add(
      http.MultipartFile.fromBytes("image", fileBytes, filename: filename),
    );

    // Diagnostic logging to help backend validation issues
    try {
      debugPrint('Uploading multipart to: $baseUrl$endpoint');
      debugPrint('Multipart fields: ${request.fields}');
      if (request.files.isNotEmpty) {
        final f = request.files.first;
        debugPrint(
          'Uploading file: name=${f.filename}, length=${fileBytes.length}',
        );
      }

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      debugPrint('Multipart response status: ${response.statusCode}');
      debugPrint('Multipart response body: ${response.body}');

      return _processResponse(response);
    } catch (e) {
      debugPrint('uploadMultipart exception: $e');
      rethrow;
    }
  }

  dynamic _processResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    }

    throw Exception("Erro: ${response.statusCode} - ${response.body}");
  }
}

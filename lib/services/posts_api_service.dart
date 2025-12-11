import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/posts.dart';
import '../config/config.dart';

class PostsApiService {
  final String baseUrl = Config.apiUrl;

  Future<List<Posts>> getPosts({String? city}) async {
    final url = Uri.parse('$baseUrl/posts${city != null ? "?city=$city" : ""}');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      List data = jsonDecode(response.body);
      return data.map((p) => Posts.fromJson(p)).toList();
    }

    throw Exception("Erro ao buscar posts");
  }

  Future<bool> createPost({
    required String title,
    required String description,
    required String city,
    required String imagePath,
  }) async {
    var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/posts'));

    request.fields['title'] = title;
    request.fields['description'] = description;
    request.fields['city'] = city;
    request.files.add(await http.MultipartFile.fromPath('image', imagePath));

    var response = await request.send();
    return response.statusCode == 201 || response.statusCode == 200;
  }
}

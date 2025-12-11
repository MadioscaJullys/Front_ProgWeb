import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'base_post_api_service.dart';
import 'auth_service.dart';
import '../models/posts.dart';

class PostsService {
  final BasePostApiService api = BasePostApiService();
  final AuthService authService;

  PostsService(this.authService);

  Future<List<Posts>> getPosts({String? city}) async {
    final token = authService.token;

    final data = await api.get(
      "/posts/${city != null && city.isNotEmpty ? '?city=$city' : ''}",
      token: token,
    );

    return (data as List).map((json) => Posts.fromJson(json)).toList();
  }

  Future<Posts> getPost(int id) async {
    final token = authService.token;

    final data = await api.get("/posts/$id/", token: token);
    return Posts.fromJson(data);
  }

  Future<Posts> createPost({
    required String title,
    required String description,
    required String city,
    required Uint8List imageBytes,
    required String filename,
  }) async {
    final token = authService.token;

    try {
      final data = await api.uploadMultipart(
        endpoint: "/posts/",
        fields: {"title": title, "description": description, "city": city},
        fileBytes: imageBytes,
        filename: filename,
        token: token,
      );

      return Posts.fromJson(data);
    } catch (e) {
      debugPrint('Multipart upload failed: $e');

      // Fallback: some backends expect a JSON body with base64 image instead of multipart.
      // Try sending a JSON payload with image base64 to handle those cases.
      try {
        final base64Image = base64Encode(imageBytes);
        final body = {
          'title': title,
          'description': description,
          'city': city,
          'image_base64': base64Image,
          'filename': filename,
        };

        final data = await api.post('/posts/', body, token: token);
        return Posts.fromJson(data);
      } catch (e2) {
        debugPrint('Fallback JSON upload also failed: $e2');
        rethrow;
      }
    }
  }

  Future<void> deletePost(int id) async {
    final token = authService.token;
    await api.get("/posts/delete/$id", token: token);
  }
}

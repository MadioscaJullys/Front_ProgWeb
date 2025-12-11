import '../config/config.dart';

class Posts {
  final int id;
  final String title;
  final String description;
  final String imageUrl;
  final String city;
  final String createdAt;
  final int userId;

  Posts({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.city,
    required this.createdAt,
    required this.userId,
  });

  factory Posts.fromJson(Map<String, dynamic> json) {
    String safeString(dynamic v) {
      if (v == null) return '';
      return v.toString();
    }

    int safeInt(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      return int.tryParse(v.toString()) ?? 0;
    }

    final rawImage = safeString(
      json['image_url'] ??
          json['image_path'] ??
          json['image'] ??
          json['imagePath'],
    );

    String resolvedImageUrl = '';

    // 1) Se servidor retornou um campo de URL/arquivo, resolvemos para uma URL absoluta
    if (rawImage.isNotEmpty) {
      if (rawImage.startsWith('http')) {
        resolvedImageUrl = rawImage;
      } else {
        var path = rawImage.replaceAll('\\', '/');
        if (path.startsWith('/')) path = path.substring(1);

        var baseFinal = Config.apiUrl;
        while (baseFinal.endsWith('/')) {
          baseFinal = baseFinal.substring(0, baseFinal.length - 1);
        }

        resolvedImageUrl = '$baseFinal/$path';
      }
    }

    // 2) Fallback: alguns endpoints fornecem um data URI/base64 no campo `image_data_url`
    //    — use-o diretamente para exibir a imagem no cliente (especialmente na web).
    if (resolvedImageUrl.isEmpty) {
      final imgData = json['image_data_url'] ?? json['imageDataUrl'];
      if (imgData != null && imgData is String && imgData.startsWith('data:')) {
        resolvedImageUrl = imgData;
      }
    }

    return Posts(
      id: safeInt(json['id']),
      title: safeString(json['title']),
      description: safeString(json['description']),
      imageUrl: resolvedImageUrl,
      city: safeString(json['city']),
      createdAt: safeString(json['created_at'] ?? json['createdAt']),
      userId: safeInt(json['user_id'] ?? json['userId']),
    );
  }
}

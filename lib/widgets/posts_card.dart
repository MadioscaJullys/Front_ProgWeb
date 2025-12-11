import 'package:flutter/material.dart';
import '../models/posts.dart';
import '../theme/app_colors.dart';

class PostCard extends StatelessWidget {
  final Posts post;

  const PostCard({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.network(post.imageUrl, fit: BoxFit.cover),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(post.title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.green,
                  fontSize: 18,
                )),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(post.description),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text("Cidade: ${post.city}",
                style: TextStyle(color: Colors.grey[600])),
          ),
        ],
      ),
    );
  }
}

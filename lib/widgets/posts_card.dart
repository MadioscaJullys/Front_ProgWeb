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
          // Exibe a imagem inteira sem recorte excessivo e com largura limitada.
          if (post.imageUrl.isNotEmpty)
            LayoutBuilder(
              builder: (context, constraints) {
                final maxWidth = constraints.maxWidth;
                final imageWidth = maxWidth > 400 ? 400.0 : maxWidth;
                return Center(
                  child: Container(
                    width: imageWidth,
                    height: 200,
                    color: Colors.grey[100],
                    child: Image.network(
                      post.imageUrl,
                      fit: BoxFit.contain,
                      width: imageWidth,
                      height: 200,
                      errorBuilder: (ctx, err, stack) => Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Icon(
                          Icons.broken_image,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                      ),
                      loadingBuilder: (ctx, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return SizedBox(
                          height: 48,
                          child: Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                        (loadingProgress.expectedTotalBytes ??
                                            1)
                                  : null,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),

          // Removido o título — o conteúdo do post deve ser somente descrição, imagem e cidade.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(post.description),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Text(
              'Cidade: ${post.city}',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'dart:convert';

class UserAvatar extends StatelessWidget {
  final String? profileImageUrl;
  final String? profileImageBase64;
  final String? fallbackText;
  final double size;
  final Color? backgroundColor;

  const UserAvatar({
    Key? key,
    this.profileImageUrl,
    this.profileImageBase64,
    this.fallbackText,
    this.size = 40,
    this.backgroundColor,
  }) : super(key: key);

  /// Detecta se o formato é AVIF pela assinatura do base64 ou cabeçalho MIME
  bool _isAvifFormat(String base64String) {
    // Verifica primeiro pelo cabeçalho MIME (mais confiável)
    if (base64String.toLowerCase().contains('data:image/avif')) {
      return true;
    }

    // Verifica pela assinatura do base64 (importante para casos onde o cabeçalho foi mudado)
    String cleanBase64 = base64String;
    if (cleanBase64.contains(',')) {
      cleanBase64 = cleanBase64.split(',')[1];
    }

    // Assinatura AVIF: mesmo que o cabeçalho diga JPEG, se o conteúdo é AVIF, não vai funcionar
    return cleanBase64.startsWith('AAAAHGZ0eXBh');
  }

  /// Constrói um widget informativo sobre o estado da conversão
  Widget _buildConversionInfoFallback() {
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: backgroundColor ?? Colors.blue[100],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.sync, size: size * 0.35, color: Colors.blue[800]),
          if (size > 50)
            Text(
              'CONV',
              style: TextStyle(
                fontSize: size * 0.12,
                color: Colors.blue[800],
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }

  /// Constrói um widget de fallback específico para AVIF
  Widget _buildAvifFallback() {
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: backgroundColor ?? Colors.orange[100],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_not_supported,
            size: size * 0.35,
            color: Colors.orange[700],
          ),
          if (size > 50)
            Text(
              'AVIF',
              style: TextStyle(
                fontSize: size * 0.12,
                color: Colors.orange[700],
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Se tem imagem em base64, usa ela
    if (profileImageBase64 != null && profileImageBase64!.isNotEmpty) {
      // Verifica se é AVIF ANTES de tentar decodificar
      if (_isAvifFormat(profileImageBase64!)) {
        // Detecta se tem cabeçalho JPEG mas conteúdo AVIF (simulação de conversão)
        bool hasJpegHeader = profileImageBase64!.toLowerCase().contains(
          'data:image/jpeg',
        );

        if (hasJpegHeader) {
          // Backend simulou conversão mas o conteúdo ainda é AVIF
          return _buildConversionInfoFallback();
        } else {
          // AVIF puro - não é suportado pelo Flutter
          return _buildAvifFallback();
        }
      }

      try {
        // Remove prefixo data:image se existir
        String base64String = profileImageBase64!;
        if (base64String.contains(',')) {
          base64String = base64String.split(',')[1];
        }

        final bytes = base64Decode(base64String);

        return CircleAvatar(
          radius: size / 2,
          backgroundColor: backgroundColor ?? Colors.grey[300],
          child: ClipOval(
            child: Image.memory(
              bytes,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                // Fallback para outros erros de imagem
                return Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: backgroundColor ?? Colors.red[100],
                  ),
                  child: Center(
                    child: Icon(
                      Icons.broken_image,
                      size: size * 0.4,
                      color: Colors.red[700],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      } catch (e) {
        // Se falhar ao decodificar, usa fallback
      }
    }

    // Se tem URL, usa ela
    if (profileImageUrl != null && profileImageUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: size / 2,
        backgroundColor: backgroundColor ?? Colors.grey[300],
        child: ClipOval(
          child: Image.network(
            profileImageUrl!,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildFallback();
            },
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                      : null,
                ),
              );
            },
          ),
        ),
      );
    }

    // Fallback: mostra iniciais ou ícone
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: backgroundColor ?? Colors.blue,
      child: _buildFallback(),
    );
  }

  Widget _buildFallback() {
    if (fallbackText != null && fallbackText!.isNotEmpty) {
      return Text(
        fallbackText![0].toUpperCase(),
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.4,
          fontWeight: FontWeight.bold,
        ),
      );
    }

    return Icon(Icons.person, color: Colors.white, size: size * 0.6);
  }
}

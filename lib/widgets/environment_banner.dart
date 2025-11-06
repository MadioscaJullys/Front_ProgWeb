import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../config/config.dart';

/// Widget que mostra um banner indicando o ambiente (apenas em modo debug)
class EnvironmentBanner extends StatelessWidget {
  final Widget child;

  const EnvironmentBanner({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Só mostra o banner em modo debug
    if (kDebugMode) {
      return Directionality(
        textDirection: TextDirection.ltr,
        child: Banner(
          message: Config.apiUrl.contains('localhost') ? 'DEV' : 'PROD',
          location: BannerLocation.topEnd,
          color: Config.apiUrl.contains('localhost') ? Colors.green : Colors.red,
          child: child,
        ),
      );
    }
    return child;
  }
}

/// Widget para mostrar informações de debug na tela
class DebugInfo extends StatelessWidget {
  const DebugInfo({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(8),
      color: Colors.black87,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🔧 Debug Info',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 4),
          Text(
            'API: ${Config.apiUrl}',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          Text(
            'Versão: ${Config.appVersion}',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          Text(
            'Plataforma: ${Config.isWeb ? 'Web' : 'Mobile'}',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

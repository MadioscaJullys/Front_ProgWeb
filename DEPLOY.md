# Deploy do Frontend Flutter

## 🌐 Configuração de Ambientes

O aplicativo está configurado para usar automaticamente a URL correta da API:

- **Desenvolvimento** (`flutter run`): `http://localhost:8000`
- **Produção** (`flutter build web`): `https://Back_ProgWeb.onrender.com`

## 🚀 Como fazer Deploy para Produção

### 1. Build para Web

```bash
cd Front_ProgWeb
flutter build web --release
```

Os arquivos compilados estarão em `build/web/`

### 2. Configurar CORS no Backend

Certifique-se de que o backend em produção aceita requisições do domínio do frontend.

No arquivo `main.py` da API, adicione o domínio do frontend no CORS:

```python
if APP_PROFILE == "PROD":
    app.add_middleware(
        CORSMiddleware,
        allow_origins=[
            "https://seu-dominio-frontend.com",
            "https://Front_ProgWeb.vercel.app"  # exemplo
        ],
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )
```

### 3. Opções de Hospedagem

#### Vercel (Recomendado)
```bash
# Instalar Vercel CLI
npm i -g vercel

# Fazer deploy
cd Front_ProgWeb
flutter build web --release
cd build/web
vercel --prod
```

#### Firebase Hosting
```bash
firebase init hosting
firebase deploy
```

#### Netlify
1. Arraste a pasta `build/web` para netlify.com
2. Ou use Netlify CLI:
```bash
netlify deploy --prod --dir=build/web
```

## 🧪 Testar Localmente o Build de Produção

Para testar como ficará em produção:

```bash
flutter build web --release
cd build/web
python -m http.server 8080
```

Abra: http://localhost:8080

## 📝 Variáveis de Ambiente

As configurações estão em: `lib/config/config.dart`

Para alterar as URLs:
```dart
static const String productionApiUrl = 'https://Back_ProgWeb.onrender.com';
static const String developmentApiUrl = 'http://localhost:8000';
```

## 🔍 Verificar Ambiente Atual

Ao iniciar o app, será impresso no console:
```
🚀 App iniciado
🌐 API URL: https://Back_ProgWeb.onrender.com
📦 Versão: 1.0.0
🔧 Modo: PRODUÇÃO
```

## ⚠️ Checklist Antes do Deploy

- [ ] Backend em produção está funcionando
- [ ] CORS configurado no backend para aceitar o domínio do frontend
- [ ] Testado localmente com `flutter build web --release`
- [ ] Todas as funcionalidades testadas
- [ ] URLs da API corretas no `config.dart`

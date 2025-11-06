# 📋 Resumo das Alterações - Deploy Frontend

## ✅ Arquivos Criados/Modificados

### 1. **lib/config/config.dart** (NOVO)
Configuração centralizada do app com:
- URL da API para desenvolvimento: `http://localhost:8000`
- URL da API para produção: `https://Back_ProgWeb.onrender.com`
- Detecção automática do ambiente (dev/prod)
- Configurações de timeout

### 2. **lib/services/base_api_service.dart** (MODIFICADO)
- Agora usa `Config.apiUrl` em vez de URL hardcoded
- Detecta automaticamente o ambiente
- Usa configurações centralizadas

### 3. **lib/main.dart** (MODIFICADO)
- Adicionado logs de inicialização mostrando qual API está sendo usada
- Adicionado `EnvironmentBanner` para mostrar DEV/PROD em modo debug

### 4. **lib/widgets/environment_banner.dart** (NOVO)
- Banner visual mostrando se está em DEV (verde) ou PROD (vermelho)
- Apenas visível em modo debug
- Widget de debug info opcional

### 5. **DEPLOY.md** (NOVO)
- Guia completo de deploy
- Instruções para Vercel, Firebase e Netlify
- Checklist pré-deploy
- Como testar localmente o build de produção

## 🎯 Como Funciona

### Em Desenvolvimento (`flutter run`)
```dart
Config.apiUrl // retorna: http://localhost:8000
```
- Banner verde com "DEV" aparece no canto superior direito
- Console mostra: "🔧 Modo: DESENVOLVIMENTO"

### Em Produção (`flutter build web --release`)
```dart
Config.apiUrl // retorna: https://Back_ProgWeb.onrender.com
```
- Nenhum banner aparece (modo release)
- App aponta para API de produção

## 🚀 Próximos Passos

1. **Testar localmente:**
   ```bash
   cd programacaoiii_front
   flutter run -d chrome
   ```
   Deve aparecer banner verde "DEV" e no console mostrar localhost

2. **Testar build de produção:**
   ```bash
   flutter build web --release
   cd build/web
   python -m http.server 8080
   ```
   Acesse http://localhost:8080 e verifique se chama a API de produção

3. **Fazer deploy:**
   - Escolha uma plataforma (Vercel, Firebase, Netlify)
   - Siga as instruções em `DEPLOY.md`
   - Configure CORS no backend para aceitar o domínio do frontend

## ⚙️ Configuração do Backend (IMPORTANTE)

Atualize o `main.py` do backend para aceitar requisições do frontend em produção:

```python
if APP_PROFILE == "PROD":
    app.add_middleware(
        CORSMiddleware,
        allow_origins=[
            "https://seu-frontend.vercel.app",  # Adicione seu domínio aqui
            "https://seu-frontend.netlify.app",
            # etc
        ],
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )
```

## 📝 Notas

- A detecção de ambiente é automática baseada em `kReleaseMode` do Flutter
- Não precisa alterar código para fazer deploy
- Em modo debug, sempre mostrará qual API está usando
- Todas as configurações estão centralizadas em `lib/config/config.dart`

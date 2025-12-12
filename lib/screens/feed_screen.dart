import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_facade.dart';
import '../services/auth_service.dart';
import '../models/posts.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({Key? key}) : super(key: key);

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  String? selectedCity;
  String? keywordQuery;
  bool isLoading = true;
  List<Posts> posts = [];

  List<String> cities = [];

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPosts({String? query}) async {
    if (!mounted) return;
    final api = Provider.of<ApiFacade>(context, listen: false);
    if (mounted) setState(() => isLoading = true);

    try {
      // 1) Buscar todos os posts (sem filtro) apenas para construir a lista de cidades
      final allPosts = await api.getPosts();
      final citySet = <String>{};
      for (final Posts p in allPosts) {
        try {
          final c = p.city;
          if (c.trim().isNotEmpty) citySet.add(c);
        } catch (_) {}
      }

      // 2) Tentar buscar os posts aplicando filtros no servidor (cidade e consulta)
      List<Posts> data;
      try {
        data = await api.getPosts(
          city: selectedCity,
          query: query ?? keywordQuery,
        );
      } catch (e) {
        // Se a chamada com filtro falhar, faz fallback local
        if (selectedCity == null) {
          data = allPosts;
        } else {
          data = allPosts.where((p) => p.city == selectedCity).toList();
        }

        if ((query ?? keywordQuery) != null &&
            (query ?? keywordQuery)!.isNotEmpty) {
          final q = (query ?? keywordQuery)!.toLowerCase();
          data = data
              .where(
                (p) =>
                    (p.title + ' ' + p.description).toLowerCase().contains(q),
              )
              .toList();
        }
      }

      if (!mounted) return;
      setState(() {
        posts = List<Posts>.from(data);
        cities = citySet.toList()..sort();
        // if the selected city is no longer present in allCities, clear it
        if (selectedCity != null && !cities.contains(selectedCity))
          selectedCity = null;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Erro ao carregar feed: $e")));
      } else {
        debugPrint('Erro ao carregar feed (widget desmontado): $e');
      }
    }

    if (mounted) setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade50,
      appBar: AppBar(
        backgroundColor: Colors.green.shade600,
        title: Text("Feed de Postagens", style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            tooltip: 'Sair',
            icon: Icon(Icons.logout),
            onPressed: () async {
              final auth = Provider.of<AuthService>(context, listen: false);
              await auth.logout();
              if (!mounted) return;
              Navigator.of(
                context,
              ).pushNamedAndRemoveUntil('/login', (r) => false);
            },
          ),
        ],
        centerTitle: true,
      ),

      // -------------------------
      // CONTEÚDO PRINCIPAL
      // -------------------------
      body: Column(
        children: [
          // -------------------------
          // FILTRO DE CIDADE
          // -------------------------
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Campo de busca por palavras-chave
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: 'Pesquisar por palavra-chave',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                keywordQuery = null;
                                _loadPosts(query: null);
                                setState(() {});
                              },
                            )
                          : null,
                    ),
                    onSubmitted: (value) {
                      keywordQuery = value.trim();
                      _loadPosts(query: keywordQuery);
                    },
                    onChanged: (value) => setState(() {}),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    decoration: InputDecoration(
                      labelText: "Filtrar por cidade",
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(),
                    ),
                    value: selectedCity,
                    items: [
                      DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Todas'),
                      ),
                      ...cities.map(
                        (c) =>
                            DropdownMenuItem<String?>(value: c, child: Text(c)),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() => selectedCity = value);
                      _loadPosts();
                    },
                  ),
                ),
                SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () => _loadPosts(
                    query: _searchController.text.trim().isEmpty
                        ? null
                        : _searchController.text.trim(),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                  ),
                  child: Text("Aplicar", style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),

          // -------------------------
          // LISTAGEM DE POSTS
          // -------------------------
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : posts.isEmpty
                ? Center(
                    child: Text(
                      "Nenhuma postagem encontrada",
                      style: TextStyle(fontSize: 18),
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.all(12),
                    itemCount: posts.length,
                    itemBuilder: (context, i) {
                      final post = posts[i];

                      return Card(
                        margin: EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // FOTO DO POST (mostra a imagem inteira com largura limitada)
                            if (post.imageUrl.isNotEmpty)
                              ClipRRect(
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(12),
                                ),
                                child: LayoutBuilder(
                                  builder: (ctx, constraints) {
                                    final maxWidth = constraints.maxWidth;
                                    final imageWidth = maxWidth > 400
                                        ? 400.0
                                        : maxWidth;
                                    return Center(
                                      child: Container(
                                        width: imageWidth,
                                        height: 200,
                                        color: Colors.grey[200],
                                        child: Image.network(
                                          post.imageUrl,
                                          width: imageWidth,
                                          height: 200,
                                          fit: BoxFit.contain,
                                          errorBuilder:
                                              (context, error, stack) =>
                                                  Container(
                                                    height: 200,
                                                    width: imageWidth,
                                                    color: Colors.grey[200],
                                                    alignment: Alignment.center,
                                                    child: Icon(
                                                      Icons.broken_image,
                                                      size: 48,
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),

                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Removido título (evita duplicar a descrição)
                                  Text(
                                    post.description.isNotEmpty
                                        ? post.description
                                        : "Sem descrição",
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.location_on,
                                        color: Colors.green,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        post.city.isNotEmpty
                                            ? post.city
                                            : "Cidade não informada",
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green.shade700,
        onPressed: () {
          Navigator.of(context).pushNamed('/create-post').then((_) {
            if (mounted) _loadPosts();
          });
        },
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

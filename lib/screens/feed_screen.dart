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
  bool isLoading = true;
  List<Posts> posts = [];

  List<String> cities = [];

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    if (!mounted) return;
    final api = Provider.of<ApiFacade>(context, listen: false);

    if (mounted) setState(() => isLoading = true);

    try {
      final data = await api.getPosts(city: selectedCity);

      // Build list of distinct cities from posts (Posts model)
      final citySet = <String>{};
      for (final Posts p in data) {
        try {
          final c = p.city;
          if (c.trim().isNotEmpty) citySet.add(c);
        } catch (_) {}
      }

      if (!mounted) return;
      setState(() {
        posts = List<Posts>.from(data);
        cities = citySet.toList()..sort();
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
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: "Filtrar por cidade",
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(),
                    ),
                    value: selectedCity,
                    items: cities
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (value) {
                      setState(() => selectedCity = value);
                      _loadPosts();
                    },
                  ),
                ),
                SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _loadPosts,
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
                            // FOTO DO POST
                            if (post.imageUrl.isNotEmpty)
                              ClipRRect(
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(12),
                                ),
                                child: Image.network(
                                  post.imageUrl,
                                  height: 220,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stack) =>
                                      Container(
                                        height: 220,
                                        width: double.infinity,
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

                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    post.title.isNotEmpty
                                        ? post.title
                                        : "Post sem título",
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green.shade800,
                                    ),
                                  ),
                                  SizedBox(height: 6),
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

import 'package:flutter/material.dart';
import '../services/posts_api_service.dart';
import '../widgets/posts_card.dart';
import '../models/posts.dart';
import '../theme/app_colors.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final PostsApiService api = PostsApiService();

  List<Posts> posts = [];
  String? selectedCity;

  @override
  void initState() {
    super.initState();
    loadPosts();
  }

  Future<void> loadPosts() async {
    final result = await api.getPosts(city: selectedCity);
    if (!mounted) return;

    setState(() => posts = result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Animais Perdidos e Doação"),
        backgroundColor: AppColors.green,
      ),
      body: Column(
        children: [
          DropdownButton<String>(
            hint: Text("Filtrar por cidade"),
            value: selectedCity,
            items: [
              "Fortaleza",
              "Recife",
              "São Paulo",
              "Natal",
            ].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
            onChanged: (value) {
              setState(() => selectedCity = value);
              loadPosts();
            },
          ),
          Expanded(
            child: ListView.builder(
              itemCount: posts.length,
              itemBuilder: (context, i) => PostCard(post: posts[i]),
            ),
          ),
        ],
      ),
    );
  }
}

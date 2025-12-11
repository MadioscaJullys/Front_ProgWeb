import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/posts_api_service.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_colors.dart';
import 'dart:io';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  String? selectedCity;
  File? selectedImage;

  Future pickImage() async {
    final picker = ImagePicker();
    final img = await picker.pickImage(source: ImageSource.gallery);
    if (!mounted) return;

    if (img != null) {
      setState(() => selectedImage = File(img.path));
    }
  }

  Future submit() async {
    if (selectedImage == null || selectedCity == null) return;
    final api = Provider.of<PostsApiService>(context, listen: false);

    final success = await api.createPost(
      title: titleController.text,
      description: descriptionController.text,
      city: selectedCity!,
      imagePath: selectedImage!.path,
    );

    if (!mounted) return;

    if (success) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Nova Postagem"),
        backgroundColor: AppColors.green,
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(labelText: "Título"),
            ),
            TextField(
              controller: descriptionController,
              decoration: InputDecoration(labelText: "Descrição"),
            ),
            DropdownButton<String>(
              hint: Text("Selecione a cidade"),
              value: selectedCity,
              items: [
                "Fortaleza",
                "Recife",
                "São Paulo",
                "Natal",
              ].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() => selectedCity = v),
            ),
            ElevatedButton(
              onPressed: pickImage,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.green),
              child: Text("Escolher imagem"),
            ),
            if (selectedImage != null) Image.file(selectedImage!, height: 150),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: submit,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.green),
              child: Text("Publicar"),
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../services/api_facade.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({Key? key}) : super(key: key);

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _textController = TextEditingController();
  final _cityController = TextEditingController();
  String? _imageFilename;
  Uint8List? _imageBytes;

  bool _loading = false;

  Future<void> _pickImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true, // ensure bytes are available across platforms
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      final bytes = file.bytes;

      if (bytes == null) {
        // No bytes available (very unlikely with withData:true), abort
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível ler o arquivo')),
        );
        return;
      }

      setState(() {
        _imageBytes = bytes;
        _imageFilename = file.name;
      });
    } catch (e) {
      debugPrint('Erro ao selecionar imagem: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao selecionar imagem')));
    }
  }

  Future<void> _submitPost() async {
    if (!_formKey.currentState!.validate()) return;

    if (_imageBytes == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Selecione uma imagem")));
      return;
    }

    setState(() => _loading = true);

    final api = Provider.of<ApiFacade>(context, listen: false);

    final success = await api.createPostScreen(
      text: _textController.text,
      city: _cityController.text.trim(),
      imageBytes: _imageBytes!,
      filename: _imageFilename ?? 'upload.jpg',
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Post criado com sucesso"),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erro ao criar post"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Criar Postagem"),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _textController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: "Descrição",
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? "Digite um texto" : null,
              ),

              SizedBox(height: 16),

              TextFormField(
                controller: _cityController,
                decoration: InputDecoration(
                  labelText: "Cidade",
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? "Digite uma cidade" : null,
              ),

              SizedBox(height: 16),

              _imageBytes == null
                  ? Text("Nenhuma imagem selecionada")
                  : Image.memory(_imageBytes!, height: 200, fit: BoxFit.cover),

              SizedBox(height: 10),

              ElevatedButton.icon(
                onPressed: _pickImage,
                icon: Icon(Icons.image),
                label: Text("Selecionar Imagem"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              ),

              SizedBox(height: 30),

              _loading
                  ? Center(
                      child: CircularProgressIndicator(color: Colors.green),
                    )
                  : ElevatedButton(
                      onPressed: _submitPost,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.all(16),
                        backgroundColor: Colors.green,
                      ),
                      child: Text("Publicar"),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

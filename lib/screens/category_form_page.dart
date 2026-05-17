import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/category_model.dart';

class CategoryFormPage extends StatefulWidget {
  final CategoryModel? category;
  const CategoryFormPage({super.key, this.category});

  @override
  State<CategoryFormPage> createState() => _CategoryFormPageState();
}

class _CategoryFormPageState extends State<CategoryFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.category != null) {
      _nameController.text = widget.category!.name;
    }
  }

  void _save() async {
    if (_formKey.currentState!.validate()) {
      final cat = CategoryModel(
        id: widget.category?.id,
        name: _nameController.text.trim(),
      );

      try {
        if (widget.category == null) {
          await DatabaseHelper.instance.createCategory(cat);
        } else {
          await DatabaseHelper.instance.updateCategory(cat);
        }
        if (mounted) Navigator.pop(context);
      } catch (e) {
        // O SQLite vai dar erro se tentar inserir um nome que já existe (por causa do UNIQUE)
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Erro: Categoria já existe ou nome inválido.')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category == null ? 'Nova Categoria' : 'Editar Categoria'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nome da Categoria'),
                validator: (v) => v!.isEmpty ? 'Informe o nome' : null,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _save,
                  child: const Text('Salvar Categoria'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
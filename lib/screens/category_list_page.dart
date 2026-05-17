import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/category_model.dart';
import 'category_form_page.dart';

class CategoryListPage extends StatefulWidget {
  const CategoryListPage({super.key});

  @override
  State<CategoryListPage> createState() => _CategoryListPageState();
}

class _CategoryListPageState extends State<CategoryListPage> {
  late Future<List<CategoryModel>> _categoriesFuture;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() {
      // O método readAllCategories já traz do banco com 'orderBy: name ASC'
      _categoriesFuture = DatabaseHelper.instance.readAllCategories();
    });
  }

  // Alerta de confirmação antes de deletar
  void _confirmDelete(BuildContext context, int id, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Categoria'),
        content: Text('Deseja realmente excluir a categoria "$name"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              await DatabaseHelper.instance.deleteCategory(id);
              _refresh(); // Recarrega a lista
              if (context.mounted) {
                Navigator.pop(context); // Fecha o diálogo
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Categoria removida com sucesso!')),
                );
              }
            },
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Categorias')),
      body: FutureBuilder<List<CategoryModel>>(
        future: _categoriesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final categories = snapshot.data ?? [];

          if (categories.isEmpty) {
            return const Center(child: Text('Nenhuma categoria cadastrada.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final cat = categories[index];
              return ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.blueAccent,
                  child: Icon(Icons.label, color: Colors.white, size: 20),
                ),
                title: Text(cat.name),
                // Adicionado um Row no trailing para exibir os dois botões de ação de forma limpa
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.grey),
                      tooltip: 'Editar',
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => CategoryFormPage(category: cat)),
                      ).then((_) => _refresh()),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                      tooltip: 'Excluir',
                      onPressed: () => _confirmDelete(context, cat.id!, cat.name),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CategoryFormPage()),
        ).then((_) => _refresh()),
        child: const Icon(Icons.add),
      ),
    );
  }
}
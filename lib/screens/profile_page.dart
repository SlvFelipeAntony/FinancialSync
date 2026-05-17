import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/user_model.dart';
import 'login_page.dart';
import 'edit_profile_page.dart';
import 'change_password_page.dart';
import 'category_list_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sair'),
        content: const Text('Deseja realmente encerrar sua sessão?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
                    (route) => false,
              );
            },
            child: const Text('Sair', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<User?>(
      future: DatabaseHelper.instance.getUser(1), // Usando ID 1 para testes locais
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final user = snapshot.data;
        final userName = user?.name ?? 'Usuário';
        final userEmail = user?.email ?? 'email@exemplo.com';

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const CircleAvatar(
                radius: 60,
                backgroundColor: Colors.blueAccent,
                child: Icon(Icons.person, size: 60, color: Colors.white),
              ),
              const SizedBox(height: 16),
              Text(userName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              Text(userEmail, style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 40),

              ListTile(
                leading: const Icon(Icons.edit, color: Colors.blueAccent),
                title: const Text('Editar Perfil'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  if (user != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => EditProfilePage(user: user)),
                    ).then((_) => setState(() {})); // Força atualização ao voltar
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.lock, color: Colors.blueAccent),
                title: const Text('Alterar Senha'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  if (user != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ChangePasswordPage(user: user)),
                    );
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.category, color: Colors.blueAccent),
                title: const Text('Gerenciar Categorias'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CategoryListPage()),
                  );
                },
              ),
              _buildMenuOption(Icons.info_outline, 'Sobre o Projeto'),

              const SizedBox(height: 40),

              ElevatedButton.icon(
                onPressed: () => _confirmLogout(context),
                icon: const Icon(Icons.logout),
                label: const Text('SAIR DO SISTEMA'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[50],
                  foregroundColor: Colors.red,
                  minimumSize: const Size(double.infinity, 55),
                  side: const BorderSide(color: Colors.red),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMenuOption(IconData icon, String title) {
    return ListTile(
      leading: Icon(icon, color: Colors.blueAccent),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {},
    );
  }
}
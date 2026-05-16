import 'package:flutter/material.dart';
import 'login_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

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
              // Limpa todas as telas e volta para o login (RF01)
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
          const Text('Usuário FinancialSync', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const Text('estudante@ifsuldeminas.edu.br', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 40),

          _buildMenuOption(Icons.edit, 'Editar Perfil'),
          _buildMenuOption(Icons.category, 'Gerenciar Categorias'),
          _buildMenuOption(Icons.lock, 'Alterar Senha'),
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
  }

  Widget _buildMenuOption(IconData icon, String title) {
    return ListTile(
      leading: Icon(icon, color: Colors.blueAccent),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        // Futuras implementações do projeto
      },
    );
  }
}
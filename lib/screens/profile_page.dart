import 'package:flutter/material.dart';
import 'login_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  // Função para processar o encerramento da sessão
  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Encerrar Sessão'),
        content: const Text('Tem a certeza que deseja sair do FinancialSync?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), // Fecha o diálogo
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              // 1. Limpa o histórico de rotas e volta para o Login
              // O 'route => false' garante que o utilizador não consiga voltar para a Home
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
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          const SizedBox(height: 20),
          const CircleAvatar(
            radius: 50,
            backgroundColor: Colors.blueAccent,
            child: Icon(Icons.person, size: 50, color: Colors.white),
          ),
          const SizedBox(height: 20),
          const Text(
              'Utilizador FinancialSync',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)
          ),
          const Text(
              'estudante@ifsuldeminas.edu.br',
              style: TextStyle(color: Colors.grey)
          ),
          const SizedBox(height: 30),

          // Opções de Perfil
          _buildProfileOption(Icons.security, 'Alterar Palavra-passe'),
          _buildProfileOption(Icons.notifications, 'Notificações'),
          _buildProfileOption(Icons.help_center, 'Centro de Ajuda'),

          const SizedBox(height: 40),

          // Botão de Logout
          ElevatedButton.icon(
            onPressed: () => _handleLogout(context),
            icon: const Icon(Icons.logout),
            label: const Text('Sair do Sistema'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[50],
              foregroundColor: Colors.red,
              minimumSize: const Size(double.infinity, 55),
              elevation: 0,
              side: const BorderSide(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileOption(IconData icon, String title) {
    return ListTile(
      leading: Icon(icon, color: Colors.blueAccent),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        // Funcionalidades futuras para o seu projeto
      },
    );
  }
}
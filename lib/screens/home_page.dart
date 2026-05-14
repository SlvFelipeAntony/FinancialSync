import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import 'transaction_form_page.dart';
import 'account_list_page.dart';
import 'transaction_list_page.dart';
import 'credit_card_list_page.dart';
import 'login_page.dart';
import 'profile_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  // Lista de telas para a navegação
  final List<Widget> _pages = [
    const DashboardView(),
    const TransactionListPage(),
    const CreditCardListPage(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FinancialSync', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Início'),
          BottomNavigationBarItem(icon: Icon(Icons.swap_horiz), label: 'Transações'),
          BottomNavigationBarItem(icon: Icon(Icons.credit_card), label: 'Cartões'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const TransactionFormPage())
          ).then((_) => setState(() {})); // Atualiza a home ao voltar
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Resumo Geral', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),

          // Card de Saldo Total
          _buildSummaryCard('Saldo em Contas', 'R\$ 0,00', Colors.blue),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(child: _buildSummaryCard('Receitas', 'R\$ 0,00', Colors.green)),
              const SizedBox(width: 12),
              Expanded(child: _buildSummaryCard('Despesas', 'R\$ 0,00', Colors.red)),
            ],
          ),

          const SizedBox(height: 24),
          const Text('Atividades Recentes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          // Aqui você pode adicionar um FutureBuilder para listar as últimas transações do SQLite
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, Color color) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
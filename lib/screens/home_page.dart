import 'package:flutter/material.dart';
import 'transaction_list_page.dart';
import 'account_list_page.dart';
import 'profile_page.dart';
import 'transaction_form_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  // Lista de telas principais do aplicativo
  final List<Widget> _pages = [
    const DashboardView(),        // Resumo (definido abaixo)
    const TransactionListPage(),  // Lista de Entradas/Saídas
    const AccountListPage(),      // Bancos e Carteiras
    const ProfilePage(),          // Perfil e Logout
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FinancialSync', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Início'),
          BottomNavigationBarItem(icon: Icon(Icons.swap_horiz), label: 'Transações'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance), label: 'Contas'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Abre o formulário de transação e atualiza a tela ao voltar
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const TransactionFormPage()),
          );
          setState(() {});
        },
        tooltip: 'Nova Transação',
        child: const Icon(Icons.add),
      ),
    );
  }
}

// Widget da Dashboard (Pode ser movido para um arquivo separado depois)
class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
              'Resumo Financeiro',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)
          ),
          const SizedBox(height: 20),

          _buildSummaryCard('Saldo Total', 'R\$ 0,00', Colors.blue),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(child: _buildSummaryCard('Receitas', 'R\$ 0,00', Colors.green)),
              const SizedBox(width: 12),
              Expanded(child: _buildSummaryCard('Despesas', 'R\$ 0,00', Colors.red)),
            ],
          ),

          const SizedBox(height: 30),
          const Text(
              'Dicas de Economia',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)
          ),
          const Card(
            child: ListTile(
              leading: Icon(Icons.lightbulb, color: Colors.orange),
              title: Text('Evite compras por impulso esta semana.'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            Text(
                value,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)
            ),
          ],
        ),
      ),
    );
  }
}
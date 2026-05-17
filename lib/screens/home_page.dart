import 'package:flutter/material.dart';
import 'transaction_list_page.dart';
import 'account_list_page.dart';
import 'profile_page.dart';
import '../database/database_helper.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  int _refreshKey = 0;

  List<Widget> get _pages => [
    DashboardView(key: ValueKey('dash_$_refreshKey')),
    TransactionListPage(key: ValueKey('trans_$_refreshKey')),
    AccountListPage(key: ValueKey('acc_$_refreshKey')), // Gerencia Contas e Cartões internamente
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
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() {
          _selectedIndex = index;
          _refreshKey++; // Força atualização ao alternar de aba
        }),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Início'),
          BottomNavigationBarItem(icon: Icon(Icons.swap_horiz), label: 'Transações'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance), label: 'Carteira'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }
}

// --- COLOQUE NO FINAL DO ARQUIVO home_page.dart ---

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, double>>(
      future: DatabaseHelper.instance.getDashboardSummary(),
      builder: (context, snapshot) {
        // Valores padrão enquanto carrega
        double balance = 0.0;
        double income = 0.0;
        double expense = 0.0;

        if (snapshot.hasData) {
          balance = snapshot.data!['balance'] ?? 0.0;
          income = snapshot.data!['income'] ?? 0.0;
          expense = snapshot.data!['expense'] ?? 0.0;
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Resumo Financeiro', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),

              _buildSummaryCard('Saldo Total', 'R\$ ${balance.toStringAsFixed(2)}', Colors.blue),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(child: _buildSummaryCard('Receitas', 'R\$ ${income.toStringAsFixed(2)}', Colors.green)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildSummaryCard('Despesas', 'R\$ ${expense.toStringAsFixed(2)}', Colors.red)),
                ],
              ),
            ],
          ),
        );
      },
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
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
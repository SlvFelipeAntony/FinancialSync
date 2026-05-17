import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'transaction_list_page.dart';
import 'account_list_page.dart';
import 'profile_page.dart';
import '../database/database_helper.dart';
import '../models/user_model.dart';

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
  DashboardView({super.key});

  // Lista de cores para o gráfico de pizza
  final List<Color> _chartColors = [
    Colors.blueAccent, Colors.redAccent, Colors.greenAccent,
    Colors.orangeAccent, Colors.purpleAccent, Colors.teal, Colors.amber
  ];

  Future<Map<String, dynamic>> _fetchDashboardData() async {
    return {
      'summary': await DatabaseHelper.instance.getDashboardSummary(),
      'user': await DatabaseHelper.instance.getUser(1),
      'categories': await DatabaseHelper.instance.getExpensesByCategory(),
    };
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _fetchDashboardData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // Extraindo os dados do banco
        final summary = snapshot.data?['summary'] as Map<String, double>? ?? {'balance': 0.0, 'income': 0.0, 'expense': 0.0};
        final user = snapshot.data?['user'] as User?;
        final categoryData = snapshot.data?['categories'] as List<Map<String, dynamic>>? ?? [];

        final userName = user?.name.split(' ').first ?? 'Usuário'; // Pega só o primeiro nome

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- CABEÇALHO COM SAUDAÇÃO ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Olá, $userName!', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      const Text('Aqui está o seu resumo financeiro.', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                  const CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.blueAccent,
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // --- CARD PRINCIPAL (SALDO) COM GRADIENTE ---
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E3C72), Color(0xFF2A5298)], // Gradiente azul elegante
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Saldo Total', style: TextStyle(color: Colors.white70, fontSize: 16)),
                    const SizedBox(height: 8),
                    Text(
                        'R\$ ${summary['balance']!.toStringAsFixed(2).replaceAll('.', ',')}',
                        style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // --- CARDS MENORES (RECEITAS E DESPESAS) ---
              Row(
                children: [
                  Expanded(child: _buildMiniCard('Receitas', summary['income']!, Colors.green, Icons.arrow_upward)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildMiniCard('Despesas', summary['expense']!, Colors.red, Icons.arrow_downward)),
                ],
              ),

              const SizedBox(height: 32),
              const Text('Despesas por Categoria (Mês)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

              // --- GRÁFICO DE PIZZA (FL_CHART) ---
              if (categoryData.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(16)),
                  child: const Text('Nenhuma despesa registrada neste mês.', style: TextStyle(color: Colors.grey)),
                )
              else
                Container(
                  height: 250, // Altura do gráfico
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))],
                  ),
                  child: Row(
                    children: [
                      // O Gráfico em si
                      Expanded(
                        flex: 5,
                        child: PieChart(
                          PieChartData(
                            sectionsSpace: 2,
                            centerSpaceRadius: 30, // Faz virar um gráfico de "Rosca" (Donut)
                            sections: List.generate(categoryData.length, (index) {
                              final data = categoryData[index];
                              final value = (data['total'] as num).toDouble();
                              return PieChartSectionData(
                                color: _chartColors[index % _chartColors.length],
                                value: value,
                                title: '', // Esconde o título dentro da fatia para ficar limpo
                                radius: 40,
                              );
                            }),
                          ),
                        ),
                      ),
                      // A Legenda do Gráfico
                      Expanded(
                        flex: 4,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: List.generate(categoryData.length, (index) {
                            final data = categoryData[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4.0),
                              child: Row(
                                children: [
                                  Container(
                                    width: 12, height: 12,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _chartColors[index % _chartColors.length],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      data['category'],
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                      maxLines: 1, overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ),
                      )
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // Widget construtor para os mini cards de receita e despesa
  Widget _buildMiniCard(String title, double value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
              'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)
          ),
        ],
      ),
    );
  }
}
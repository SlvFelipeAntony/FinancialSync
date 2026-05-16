import 'package:flutter/material.dart';
import '../database/database_helper.dart';

class TransactionListPage extends StatefulWidget {
  const TransactionListPage({super.key});

  @override
  State<TransactionListPage> createState() => _TransactionListPageState();
}

class _TransactionListPageState extends State<TransactionListPage> {
  String _filter = 'todos'; // Opções: 'todos', 'entrada', 'saida'

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico de Transações'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildFilterChip('Todas', 'todos'),
                const SizedBox(width: 8),
                _buildFilterChip('Entradas', 'entrada'),
                const SizedBox(width: 8),
                _buildFilterChip('Saídas', 'saida'),
              ],
            ),
          ),
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: DatabaseHelper.instance.getFilteredTransactions(_filter),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Nenhuma transação encontrada.'));
          }

          final transactions = snapshot.data!;
          return ListView.builder(
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              final t = transactions[index];
              final isIncome = t['type'] == 'entrada';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isIncome ? Colors.green[50] : Colors.red[50],
                    child: Icon(
                      isIncome ? Icons.trending_up : Icons.trending_down,
                      color: isIncome ? Colors.green : Colors.red,
                    ),
                  ),
                  title: Text(t['description']),
                  subtitle: Text("${t['category']} • ${t['account_name']}"),
                  trailing: Text(
                    "${isIncome ? '+' : '-'} R\$ ${t['value'].toStringAsFixed(2)}",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isIncome ? Colors.green : Colors.red,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    return ChoiceChip(
      label: Text(label),
      selected: _filter == value,
      onSelected: (selected) {
        if (selected) setState(() => _filter = value);
      },
    );
  }
}
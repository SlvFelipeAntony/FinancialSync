import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/transaction_model.dart';
import 'transaction_form_page.dart';

class TransactionListPage extends StatefulWidget {
  const TransactionListPage({super.key});

  @override
  State<TransactionListPage> createState() => _TransactionListPageState();
}

class _TransactionListPageState extends State<TransactionListPage> {
  String _filter = 'todos';
  bool _showDailyBalance = true; // true = Balanço (Entradas - Saídas), false = Saldo Final do Dia

  void _confirmDeleteTransaction(BuildContext context, AccountTransaction trans) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir Transação'),
        content: Text('Deseja apagar "${trans.description}"? O saldo será recalculado.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
          TextButton(
            onPressed: () async {
              await DatabaseHelper.instance.deleteTransaction(trans);
              if (context.mounted) {
                Navigator.pop(dialogContext);
                setState(() {});
              }
            },
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // Função combinada para buscar transações e o saldo atual ao mesmo tempo
  Future<Map<String, dynamic>> _fetchPageData() async {
    final trans = await DatabaseHelper.instance.getFilteredTransactions(_filter);
    final currentTotalBalance = await DatabaseHelper.instance.getTotalBalance();
    return {
      'transactions': trans,
      'currentBalance': currentTotalBalance,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
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

          Expanded(
            child: FutureBuilder<Map<String, dynamic>>(
              future: _fetchPageData(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final transactions = snapshot.data!['transactions'] as List<Map<String, dynamic>>;
                final currentBalance = snapshot.data!['currentBalance'] as double;

                if (transactions.isEmpty) {
                  return const Center(child: Text('Nenhuma transação encontrada.'));
                }

                // 1. Agrupar as transações por data e calcular o Balanço Diário
                Map<String, List<Map<String, dynamic>>> grouped = {};
                Map<String, double> dailyNets = {};

                for (var t in transactions) {
                  String date = t['date'];
                  if (!grouped.containsKey(date)) grouped[date] = [];
                  grouped[date]!.add(t);

                  double val = (t['value'] as num).toDouble();
                  dailyNets[date] = (dailyNets[date] ?? 0.0) + (t['type'] == 'entrada' ? val : -val);
                }

                // 2. Ordenar as datas (da mais recente para a mais antiga)
                final sortedDates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

                // 3. Calcular o Saldo Final (Apenas se o filtro for 'todos')
                Map<String, double> endOfDayBalances = {};
                if (_filter == 'todos') {
                  double runningBalance = currentBalance;
                  for (String d in sortedDates) {
                    endOfDayBalances[d] = runningBalance;
                    runningBalance -= dailyNets[d]!; // "Desfaz" o dia atual para descobrir o saldo do dia anterior
                  }
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 85),
                  itemCount: sortedDates.length,
                  itemBuilder: (context, index) {
                    final dateStr = sortedDates[index];
                    final dayTransactions = grouped[dateStr]!;
                    final dailyNet = dailyNets[dateStr]!;

                    // Formatar a data para o cabeçalho
                    String formattedDate = dateStr;
                    try {
                      final parsed = DateTime.parse(dateStr);
                      formattedDate = "${parsed.day.toString().padLeft(2,'0')}/${parsed.month.toString().padLeft(2,'0')}/${parsed.year}";
                    } catch (_) {}

                    // Definir o texto e cor do cabeçalho direito baseado no toggle
                    String rightHeaderText;
                    Color? rightHeaderColor;

                    if (_filter == 'todos' && !_showDailyBalance) {
                      // Modo: Saldo Final do Dia
                      rightHeaderText = "Saldo: R\$ ${endOfDayBalances[dateStr]!.toStringAsFixed(2)}";
                      rightHeaderColor = Colors.blueGrey[800];
                    } else {
                      // Modo: Balanço do Dia
                      rightHeaderText = "Balanço: ${dailyNet >= 0 ? '+' : ''} R\$ ${dailyNet.toStringAsFixed(2)}";
                      rightHeaderColor = dailyNet >= 0 ? Colors.green[700] : Colors.red[700];
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // --- CABEÇALHO DA DATA ---
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          color: Colors.grey[100],
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(formattedDate, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Ícone de Toggle (só aparece se filtro == 'todos')
                                  if (_filter == 'todos')
                                    Padding(
                                      padding: const EdgeInsets.only(right: 8.0),
                                      child: InkWell(
                                        onTap: () => setState(() => _showDailyBalance = !_showDailyBalance),
                                        child: Icon(
                                            _showDailyBalance ? Icons.swap_horiz : Icons.swap_horiz,
                                            size: 18,
                                            color: Colors.blueAccent
                                        ),
                                      ),
                                    ),
                                  Text(
                                    rightHeaderText,
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: rightHeaderColor),
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),

                        // --- CARDS DO DIA ---
                        ...dayTransactions.map((tMap) {
                          final transObj = AccountTransaction(
                            id: tMap['id'],
                            type: tMap['type'],
                            description: tMap['description'],
                            value: (tMap['value'] as num).toDouble(),
                            category: tMap['category'],
                            date: tMap['date'],
                            time: tMap['time'],
                            application: tMap['application'],
                            link: tMap['link'],
                            accountsId: tMap['accounts_id'],
                          );

                          final isIncome = transObj.type == 'entrada';
                          final isInvoicePayment = transObj.category == 'Cartão de Crédito' && transObj.description.startsWith('Pagamento Fatura');
                          String displayTime = (transObj.time != null && transObj.time!.length >= 5)
                              ? transObj.time!.substring(0, 5)
                              : '';

                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            elevation: 0.5,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(color: Colors.grey.shade200)
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              isIncome ? Icons.trending_up : Icons.trending_down,
                                              color: isIncome ? Colors.green : Colors.red,
                                              size: 18,
                                            ),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                transObj.description,
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text("${transObj.category} • ${tMap['account_name']}", style: TextStyle(color: Colors.grey[700], fontSize: 13)),
                                        const SizedBox(height: 2),
                                        Text(displayTime, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            "${isIncome ? '+' : '-'} R\$ ${transObj.value.toStringAsFixed(2)}",
                                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isIncome ? Colors.green : Colors.red),
                                          ),
                                          // Só exibe os botões se NÃO for pagamento de fatura
                                          if (!isInvoicePayment) ...[
                                            PopupMenuButton<String>(
                                              icon: const Icon(Icons.more_vert, size: 20, color: Colors.grey),
                                              padding: EdgeInsets.zero,
                                              onSelected: (value) {
                                                if (value == 'edit') {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(builder: (context) => TransactionFormPage(transaction: transObj)),
                                                  ).then((_) => setState(() {}));
                                                } else if (value == 'delete') {
                                                  _confirmDeleteTransaction(context, transObj);
                                                }
                                              },
                                              itemBuilder: (context) => [
                                                const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 18), SizedBox(width: 8), Text('Editar')])),
                                                const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, size: 18, color: Colors.red), SizedBox(width: 8), Text('Excluir')])),
                                              ],
                                            ),
                                          ] else ...[
                                            const Padding(
                                              padding: EdgeInsets.only(left: 8.0),
                                              child: Icon(Icons.lock_outline, size: 16, color: Colors.grey),
                                            )
                                          ]
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                        const SizedBox(height: 12),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_transactions',
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const TransactionFormPage()),
        ).then((_) => setState(() {})),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    return ChoiceChip(
      label: Text(label),
      selected: _filter == value,
      onSelected: (selected) {
        if (selected) setState(() {
          _filter = value;
          if (_filter != 'todos') _showDailyBalance = true; // Força "Balanço" ao usar filtros
        });
      },
    );
  }
}
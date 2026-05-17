import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/credit_card_model.dart';
import '../models/credit_transaction_model.dart';
import 'credit_transaction_form_page.dart';
import 'pay_invoice_page.dart';

class InvoiceViewPage extends StatefulWidget {
  final CreditCard card;
  const InvoiceViewPage({super.key, required this.card});

  @override
  State<InvoiceViewPage> createState() => _InvoiceViewPageState();
}

class _InvoiceViewPageState extends State<InvoiceViewPage> {
  double _calculatedTotal = 0.0;
  DateTime _currentViewMonth = DateTime.now(); // Mês selecionado no calendário

  final List<String> _monthNames = ['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun', 'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'];

  void _changeMonth(int increment) {
    setState(() {
      _currentViewMonth = DateTime(_currentViewMonth.year, _currentViewMonth.month + increment, 1);
    });
  }

  void _confirmDelete(BuildContext context, CreditTransaction trans) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir Transação'),
        content: const Text('Atenção: Como esta é a primeira parcela, TODAS as outras parcelas vinculadas a esta compra serão excluídas e o limite do cartão será restabelecido por completo.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
          TextButton(
            onPressed: () async {
              await DatabaseHelper.instance.deleteCreditTransaction(trans);
              if (context.mounted) {
                Navigator.pop(dialogContext);
                setState(() {});
              }
            },
            child: const Text('Excluir Tudo', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String yearMonthFilter = "${_currentViewMonth.year}-${_currentViewMonth.month.toString().padLeft(2, '0')}";
    String displayMonth = "${_monthNames[_currentViewMonth.month - 1]} ${_currentViewMonth.year}";

    return Scaffold(
      appBar: AppBar(title: Text('Fatura: ${widget.card.name}')),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.only(top: 16, bottom: 24, left: 24, right: 24),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.blueGrey[900],
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
            ),
            child: Column(
              children: [
                // --- SELETOR DE MÊS ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left, color: Colors.white),
                      onPressed: () => _changeMonth(-1),
                    ),
                    Text(
                      displayMonth.toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right, color: Colors.white),
                      onPressed: () => _changeMonth(1),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('TOTAL DO MÊS', style: TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 8),
                FutureBuilder<double>(
                  future: DatabaseHelper.instance.getInvoiceTotal(widget.card.id!, yearMonthFilter),
                  builder: (context, snapshot) {
                    _calculatedTotal = snapshot.data ?? 0.0;
                    return Text('R\$ ${_calculatedTotal.toStringAsFixed(2)}',
                        style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold));
                  },
                ),
                const SizedBox(height: 8),
                Text('Vence dia ${widget.card.expirationDate}', style: const TextStyle(color: Colors.greenAccent)),
                const SizedBox(height: 16),

                ElevatedButton.icon(
                  onPressed: () {
                    if (_calculatedTotal <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Esta fatura não possui saldo devedor para liquidação.')),
                      );
                      return;
                    }
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PayInvoicePage(card: widget.card, invoiceTotal: _calculatedTotal),
                      ),
                    ).then((success) {
                      if (success == true) setState(() {});
                    });
                  },
                  icon: const Icon(Icons.payment),
                  label: const Text('PAGAR FATURA'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.greenAccent[700],
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: DatabaseHelper.instance.getInvoiceTransactions(widget.card.id!, yearMonthFilter),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final list = snapshot.data!;
                if (list.isEmpty) return const Center(child: Text('Nenhum gasto neste mês.'));

                return ListView.builder(
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final tMap = list[index];
                    final transObj = CreditTransaction.fromMap(tMap);
                    final isIncome = transObj.type == 'entrada';
                    // NOVO: Regra de identificação
                    final isPayment = transObj.category == 'Pagamento' && transObj.description == 'Pagamento de Fatura';

                    String parcelasStr = transObj.installment > 1
                        ? ' • (${transObj.currentInstallment}/${transObj.installment})'
                        : '';

                    // --- SOLUÇÃO: Sincronização visual da data original ---
                    String formattedDate = transObj.date;
                    try {
                      final parsed = DateTime.parse(transObj.date);
                      // Retrocede os meses da parcela atual para encontrar o dia exato da compra original
                      final originalDate = DateTime(parsed.year, parsed.month - (transObj.currentInstallment - 1), parsed.day);
                      formattedDate = "${originalDate.day.toString().padLeft(2,'0')}/${originalDate.month.toString().padLeft(2,'0')}/${originalDate.year}";
                    } catch (_) {}

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isIncome ? Colors.green[50] : Colors.red[50],
                        child: Icon(
                            isIncome ? Icons.assignment_return : Icons.shopping_bag_outlined,
                            color: isIncome ? Colors.green : Colors.redAccent
                        ),
                      ),
                      title: Text("${transObj.description}$parcelasStr", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      // Exibe uma pequena tag informativa nas parcelas dependentes
                      subtitle: Text(
                        transObj.currentInstallment == 1
                            ? "$formattedDate • ${transObj.category}"
                            : "$formattedDate • ${transObj.category} • Gerenciado na Parc. 1",
                        style: TextStyle(fontSize: 12, color: transObj.currentInstallment == 1 ? Colors.grey[700] : Colors.blueGrey),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('R\$ ${transObj.value.toStringAsFixed(2)}',
                              style: TextStyle(fontWeight: FontWeight.bold, color: isIncome ? Colors.green : Colors.red)),

                          // --- BLINDAGEM: O menu de três pontinhos só renderiza e existe na parcela número 1 ---
                          if (transObj.currentInstallment == 1)
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert, size: 20, color: Colors.grey),
                              onSelected: (value) {
                                if (value == 'edit') {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => CreditTransactionFormPage(transaction: transObj))
                                  ).then((_) => setState(() {}));
                                } else if (value == 'delete') {
                                  _confirmDelete(context, transObj);
                                }
                              },
                              itemBuilder: (context) {
                                if (isPayment) {
                                  return [
                                    const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_forever, size: 18, color: Colors.red), SizedBox(width: 8), Text('Desfazer Pagamento')])),
                                  ];
                                }
                                return [
                                  const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 18), SizedBox(width: 8), Text('Editar Compra')])),
                                  const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, size: 18, color: Colors.red), SizedBox(width: 8), Text('Excluir Compra')])),
                                ];
                              },
                            )
                          else
                            const SizedBox(width: 40), // Espaço reservado invisível para não quebrar o alinhamento
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CreditTransactionFormPage())).then((_) => setState(() {})),
        label: const Text('Novo Gasto'),
        icon: const Icon(Icons.add_shopping_cart),
      ),
    );
  }
}
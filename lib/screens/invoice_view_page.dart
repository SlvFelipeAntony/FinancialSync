import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/credit_card_model.dart';
import '../models/credit_transaction_model.dart';
import 'credit_transaction_form_page.dart';
import 'pay_invoice_page.dart'; // Importação adicionada

class InvoiceViewPage extends StatefulWidget {
  final CreditCard card;
  const InvoiceViewPage({super.key, required this.card});

  @override
  State<InvoiceViewPage> createState() => _InvoiceViewPageState();
}

class _InvoiceViewPageState extends State<InvoiceViewPage> {
  double _calculatedTotal = 0.0; // Armazena temporariamente o valor da busca assíncrona

  void _confirmDelete(BuildContext context, CreditTransaction trans) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir Gasto'),
        content: Text('Deseja apagar "${trans.description}" da fatura? O limite do cartão será recalculado.'),
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
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Fatura: ${widget.card.name}')),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.blueGrey[900],
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
            ),
            child: Column(
              children: [
                const Text('TOTAL DA FATURA', style: TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 8),
                FutureBuilder<double>(
                  future: DatabaseHelper.instance.getInvoiceTotal(widget.card.id!),
                  builder: (context, snapshot) {
                    _calculatedTotal = snapshot.data ?? 0.0;
                    return Text('R\$ ${_calculatedTotal.toStringAsFixed(2)}',
                        style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold));
                  },
                ),
                const SizedBox(height: 8),
                Text('Vence todo dia ${widget.card.expirationDate}', style: const TextStyle(color: Colors.greenAccent)),
                const SizedBox(height: 16),

                // NOVO: Botão dinâmico inserido diretamente no cabeçalho premium
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
                        builder: (context) => PayInvoicePage(
                          card: widget.card,
                          invoiceTotal: _calculatedTotal,
                        ),
                      ),
                    ).then((success) {
                      if (success == true) setState(() {}); // Recarrega os dados locais
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
              future: DatabaseHelper.instance.getInvoiceTransactions(widget.card.id!),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final list = snapshot.data!;
                if (list.isEmpty) return const Center(child: Text('Nenhum gasto nesta fatura.'));

                return ListView.builder(
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final tMap = list[index];
                    final transObj = CreditTransaction(
                      id: tMap['id'],
                      type: tMap['type'],
                      description: tMap['description'],
                      value: (tMap['value'] as num).toDouble(),
                      category: tMap['category'],
                      date: tMap['date'],
                      installment: tMap['installment'],
                      creditCardId: tMap['credit_card_id'],
                    );

                    final isIncome = transObj.type == 'entrada';

                    String formattedDate = transObj.date;
                    try {
                      final parsed = DateTime.parse(transObj.date);
                      formattedDate = "${parsed.day.toString().padLeft(2,'0')}/${parsed.month.toString().padLeft(2,'0')}/${parsed.year}";
                    } catch (_) {}

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isIncome ? Colors.green[50] : Colors.red[50],
                        child: Icon(
                            isIncome ? Icons.assignment_return : Icons.shopping_bag_outlined,
                            color: isIncome ? Colors.green : Colors.redAccent
                        ),
                      ),
                      title: Text(transObj.description, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text("$formattedDate • ${transObj.installment}x • ${transObj.category}"),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('R\$ ${transObj.value.toStringAsFixed(2)}',
                              style: TextStyle(fontWeight: FontWeight.bold, color: isIncome ? Colors.green : Colors.red)),

                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert, size: 20, color: Colors.grey),
                            onSelected: (value) {
                              if (value == 'edit') {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => CreditTransactionFormPage(transaction: transObj)),
                                ).then((_) => setState(() {}));
                              } else if (value == 'delete') {
                                _confirmDelete(context, transObj);
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 18), SizedBox(width: 8), Text('Editar')])),
                              const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, size: 18, color: Colors.red), SizedBox(width: 8), Text('Excluir')])),
                            ],
                          ),
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
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CreditTransactionFormPage()),
        ).then((_) => setState(() {})),
        label: const Text('Novo Gasto'),
        icon: const Icon(Icons.add_shopping_cart),
      ),
    );
  }
}
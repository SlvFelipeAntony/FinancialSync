import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/credit_card_model.dart';
import 'credit_transaction_form_page.dart';

class InvoiceViewPage extends StatefulWidget {
  final CreditCard card;
  const InvoiceViewPage({super.key, required this.card});

  @override
  State<InvoiceViewPage> createState() => _InvoiceViewPageState();
}

class _InvoiceViewPageState extends State<InvoiceViewPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Fatura: ${widget.card.name}')),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
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
                    final total = snapshot.data ?? 0.0;
                    return Text('R\$ ${total.toStringAsFixed(2)}',
                        style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold));
                  },
                ),
                const SizedBox(height: 8),
                Text('Vence todo dia ${widget.card.expirationDate}', style: const TextStyle(color: Colors.greenAccent)),
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
                    final t = list[index];
                    return ListTile(
                      leading: const Icon(Icons.shopping_bag_outlined),
                      title: Text(t['description']),
                      subtitle: Text(t['date']),
                      trailing: Text('R\$ ${t['value'].toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
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
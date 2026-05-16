import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/credit_card_model.dart';

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
          // Resumo da Fatura
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            color: Colors.blueGrey[50],
            child: Column(
              children: [
                const Text('Total da Fatura Atual', style: TextStyle(fontSize: 16)),
                FutureBuilder<double>(
                  future: DatabaseHelper.instance.getInvoiceTotal(widget.card.id!),
                  builder: (context, snapshot) {
                    final total = snapshot.data ?? 0.0;
                    return Text(
                      'R\$ ${total.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.red),
                    );
                  },
                ),
                Text('Vence em: dia ${widget.card.expirationDate}', style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),

          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Align(alignment: Alignment.centerLeft, child: Text('Lançamentos', style: TextStyle(fontWeight: FontWeight.bold))),
          ),

          // Lista de Transações do Cartão
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: DatabaseHelper.instance.getInvoiceTransactions(widget.card.id!),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final list = snapshot.data!;

                return ListView.builder(
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final t = list[index];
                    return ListTile(
                      leading: const Icon(Icons.shopping_cart_outlined),
                      title: Text(t['description']),
                      subtitle: Text(t['date']),
                      trailing: Text('R\$ ${t['value'].toStringAsFixed(2)}'),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
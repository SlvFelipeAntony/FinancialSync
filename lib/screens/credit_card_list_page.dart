import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/credit_card_model.dart';
import 'credit_card_form_page.dart';
import 'invoice_view_page.dart';

class CreditCardListPage extends StatefulWidget {
  const CreditCardListPage({super.key});

  @override
  State<CreditCardListPage> createState() => _CreditCardListPageState();
}

class _CreditCardListPageState extends State<CreditCardListPage> {
  late Future<List<CreditCard>> _cardsFuture;

  @override
  void initState() {
    super.initState();
    _refreshCards();
  }

  void _refreshCards() {
    setState(() {
      _cardsFuture = DatabaseHelper.instance.readAllCreditCards();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Meus Cartões')),
      body: FutureBuilder<List<CreditCard>>(
        future: _cardsFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final cards = snapshot.data!;

          return ListView.builder(
            itemCount: cards.length,
            itemBuilder: (context, index) {
              final card = cards[index];
              return Card(
                margin: const EdgeInsets.all(8),
                color: Colors.grey[900], // Estilo "dark card"
                child: ListTile(
                  title: Text(card.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: Text('**** ${card.lastDigits}', style: const TextStyle(color: Colors.white70)),
                  trailing: Text('Limite: R\$ ${card.limitValue}', style: const TextStyle(color: Colors.greenAccent)),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => InvoiceViewPage(card: card)),
                    ).then((_) => setState(() {}));
                  },
                  onLongPress: () async {
                    await DatabaseHelper.instance.deleteCreditCard(card.id!);
                    _refreshCards();
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreditCardFormPage()),
          );
          if (result == true) _refreshCards();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
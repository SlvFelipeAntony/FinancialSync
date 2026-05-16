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
    _refresh();
  }

  void _refresh() {
    setState(() {
      _cardsFuture = DatabaseHelper.instance.readAllCreditCards();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<CreditCard>>(
        future: _cardsFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final cards = snapshot.data!;
          if (cards.isEmpty) return const Center(child: Text('Nenhum cartão cadastrado.'));

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: cards.length,
            itemBuilder: (context, index) {
              final card = cards[index];
              return GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => InvoiceViewPage(card: card)),
                ).then((_) => _refresh()),
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  color: Colors.blueGrey[900], // Visual "Premium" para cartões
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    height: 180,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(card.name.toUpperCase(),
                                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                            const Icon(Icons.contactless, color: Colors.white70),
                          ],
                        ),
                        Text('**** **** **** ${card.lastDigits}',
                            style: const TextStyle(color: Colors.white, fontSize: 20, letterSpacing: 2)),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('LIMITE DISPONÍVEL', style: TextStyle(color: Colors.white54, fontSize: 10)),
                                Text('R\$ ${card.limitValue.toStringAsFixed(2)}',
                                    style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const Icon(Icons.credit_card, color: Colors.white24, size: 40),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'addCard',
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CreditCardFormPage()),
        ).then((_) => _refresh()),
        child: const Icon(Icons.add),
      ),
    );
  }
}
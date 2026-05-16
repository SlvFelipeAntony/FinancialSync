import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/credit_transaction_model.dart';
import '../models/credit_card_model.dart';

class CreditTransactionFormPage extends StatefulWidget {
  const CreditTransactionFormPage({super.key});

  @override
  State<CreditTransactionFormPage> createState() => _CreditTransactionFormPageState();
}

class _CreditTransactionFormPageState extends State<CreditTransactionFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _descController = TextEditingController();
  final _valueController = TextEditingController();

  int? _selectedCardId;
  List<CreditCard> _cards = [];
  String _selectedCategory = 'Lazer';

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  void _loadCards() async {
    final cards = await DatabaseHelper.instance.readAllCreditCards();
    setState(() => _cards = cards);
  }

  void _save() async {
    if (_formKey.currentState!.validate() && _selectedCardId != null) {
      final trans = CreditTransaction(
        description: _descController.text,
        value: double.parse(_valueController.text),
        category: _selectedCategory,
        date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
        installment: 1, // Padrão 1 parcela (pode expandir para o RF07 depois)
        creditCardId: _selectedCardId!,
      );

      await DatabaseHelper.instance.insertCreditTransaction(trans);
      if (mounted) Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nova Compra no Crédito')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(labelText: 'Descrição da Compra'),
                validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
              ),
              TextFormField(
                controller: _valueController,
                decoration: const InputDecoration(labelText: 'Valor (R\$)'),
                keyboardType: TextInputType.number,
              ),
              DropdownButtonFormField<int>(
                hint: const Text('Selecione o Cartão'),
                items: _cards.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                onChanged: (val) => setState(() => _selectedCardId = val),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                child: const Text('Confirmar Compra'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
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
  final _installmentController = TextEditingController(text: '1');

  String _selectedType = 'saida'; // 'saida' para compra, 'entrada' para estorno
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
    if (_formKey.currentState!.validate()) {
      if (_selectedCardId == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecione um cartão')));
        return;
      }

      final trans = CreditTransaction(
        type: _selectedType,
        description: _descController.text,
        value: double.parse(_valueController.text),
        category: _selectedCategory,
        date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
        installment: int.parse(_installmentController.text),
        creditCardId: _selectedCardId!,
      );

      await DatabaseHelper.instance.insertCreditTransaction(trans);
      if (mounted) Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gasto no Cartão')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'saida', label: Text('Compra'), icon: Icon(Icons.shopping_cart)),
                  ButtonSegment(value: 'entrada', label: Text('Estorno'), icon: Icon(Icons.assignment_return)),
                ],
                selected: {_selectedType},
                onSelectionChanged: (val) => setState(() => _selectedType = val.first),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(labelText: 'Descrição (Ex: Supermercado)'),
                validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _valueController,
                      decoration: const InputDecoration(labelText: 'Valor Total (R\$)'),
                      keyboardType: TextInputType.number,
                      validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _installmentController,
                      decoration: const InputDecoration(labelText: 'Parcelas'),
                      keyboardType: TextInputType.number,
                      validator: (v) => int.tryParse(v!) == null ? 'Inválido' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: _selectedCardId,
                hint: const Text('Selecione o Cartão'),
                items: _cards.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                onChanged: (val) => setState(() => _selectedCardId = val),
                validator: (v) => v == null ? 'Obrigatório' : null,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                child: const Text('Confirmar na Fatura'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/transaction_model.dart';
import '../models/account_model.dart';

class TransactionFormPage extends StatefulWidget {
  const TransactionFormPage({super.key});

  @override
  State<TransactionFormPage> createState() => _TransactionFormPageState();
}

class _TransactionFormPageState extends State<TransactionFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _descController = TextEditingController();
  final _valueController = TextEditingController();

  String _selectedType = 'saida';
  String _selectedCategory = 'Lazer';
  int? _selectedAccountId;
  List<Account> _accounts = [];

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  void _loadAccounts() async {
    final accounts = await DatabaseHelper.instance.readAllAccounts(1);
    setState(() => _accounts = accounts);
  }

  void _save() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedAccountId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selecione uma conta bancária')),
        );
        return;
      }

      final trans = AccountTransaction(
        type: _selectedType,
        description: _descController.text,
        value: double.parse(_valueController.text),
        category: _selectedCategory,
        date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
        time: DateFormat('HH:mm:ss').format(DateTime.now()),
        accountsId: _selectedAccountId!,
      );

      await DatabaseHelper.instance.insertTransaction(trans);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nova Movimentação')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'entrada', label: Text('Receita'), icon: Icon(Icons.add)),
                  ButtonSegment(value: 'saida', label: Text('Despesa'), icon: Icon(Icons.remove)),
                ],
                selected: {_selectedType},
                onSelectionChanged: (val) => setState(() => _selectedType = val.first),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(labelText: 'Descrição'),
                validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _valueController,
                decoration: const InputDecoration(labelText: 'Valor (R\$)'),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? 'Informe o valor' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: _selectedAccountId,
                hint: const Text('Selecione a Conta de Origem/Destino'),
                items: _accounts.map((acc) => DropdownMenuItem(
                  value: acc.id,
                  child: Text(acc.name),
                )).toList(),
                onChanged: (val) => setState(() => _selectedAccountId = val),
                validator: (v) => v == null ? 'Obrigatório' : null,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                child: const Text('Confirmar Transação'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
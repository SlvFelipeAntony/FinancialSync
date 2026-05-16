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
    // Carrega contas do banco (usando ID de usuário 1 para teste)
    final accounts = await DatabaseHelper.instance.readAllAccounts(1);
    setState(() => _accounts = accounts);
  }

  void _save() async {
    if (_formKey.currentState!.validate() && _selectedAccountId != null) {
      final trans = AccountTransaction(
        type: _selectedType,
        description: _descController.text,
        value: double.parse(_valueController.text),
        category: _selectedCategory,
        date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
        accountsId: _selectedAccountId!,
      );

      await DatabaseHelper.instance.insertTransaction(trans);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nova Transação')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              DropdownButtonFormField<String>(
                value: _selectedType,
                items: const [
                  DropdownMenuItem(value: 'entrada', child: Text('Entrada (Receita)')),
                  DropdownMenuItem(value: 'saida', child: Text('Saída (Despesa)')),
                ],
                onChanged: (val) => setState(() => _selectedType = val!),
                decoration: const InputDecoration(labelText: 'Tipo'),
              ),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(labelText: 'Descrição'),
                validator: (v) => v!.isEmpty ? 'Informe a descrição' : null,
              ),
              TextFormField(
                controller: _valueController,
                decoration: const InputDecoration(labelText: 'Valor (R\$)'),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? 'Informe o valor' : null,
              ),
              DropdownButtonFormField<int>(
                hint: const Text('Selecione a Conta'),
                items: _accounts.map((acc) => DropdownMenuItem(
                  value: acc.id,
                  child: Text(acc.name),
                )).toList(),
                onChanged: (val) => setState(() => _selectedAccountId = val),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                child: const Text('Salvar Transação'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
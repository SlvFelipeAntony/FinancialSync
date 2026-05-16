import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/credit_card_model.dart';
import '../models/account_model.dart';

class CreditCardFormPage extends StatefulWidget {
  const CreditCardFormPage({super.key});

  @override
  State<CreditCardFormPage> createState() => _CreditCardFormPageState();
}

class _CreditCardFormPageState extends State<CreditCardFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _limitController = TextEditingController();
  final _digitsController = TextEditingController();
  final _closingController = TextEditingController();
  final _expirationController = TextEditingController();

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
    if (_formKey.currentState!.validate() && _selectedAccountId != null) {
      final card = CreditCard(
        name: _nameController.text,
        lastDigits: _digitsController.text,
        limitValue: double.parse(_limitController.text),
        closingDate: _closingController.text,
        expirationDate: _expirationController.text,
        accountId: _selectedAccountId!,
      );

      await DatabaseHelper.instance.createCreditCard(card);
      if (mounted) Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Novo Cartão')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nome do Cartão (Ex: Black, Platinum)'),
                validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
              ),
              TextFormField(
                controller: _digitsController,
                decoration: const InputDecoration(labelText: 'Últimos 4 dígitos'),
                keyboardType: TextInputType.number,
                maxLength: 4,
                validator: (v) => v!.length < 4 ? 'Informe 4 dígitos' : null,
              ),
              TextFormField(
                controller: _limitController,
                decoration: const InputDecoration(labelText: 'Limite Total (R\$)'),
                keyboardType: TextInputType.number,
              ),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _closingController,
                      decoration: const InputDecoration(labelText: 'Dia Fechamento'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _expirationController,
                      decoration: const InputDecoration(labelText: 'Dia Vencimento'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              DropdownButtonFormField<int>(
                hint: const Text('Conta para débito da fatura'),
                items: _accounts.map((acc) => DropdownMenuItem(
                  value: acc.id,
                  child: Text(acc.name),
                )).toList(),
                onChanged: (val) => setState(() => _selectedAccountId = val),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                child: const Text('Salvar Cartão'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
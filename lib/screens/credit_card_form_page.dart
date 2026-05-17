import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Máscara de Moeda (Currency Mask)
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

      String cleanValue = _limitController.text.replaceAll('.', '').replaceAll(',', '.');

      final card = CreditCard(
        name: _nameController.text,
        lastDigits: _digitsController.text,
        limitValue: double.parse(cleanValue),
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
      appBar: AppBar(title: const Text('Novo Cartão de Crédito')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nome do Cartão (Ex: Nubank Black)'),
                validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _digitsController,
                decoration: const InputDecoration(labelText: 'Últimos 4 dígitos'),
                keyboardType: TextInputType.number,
                maxLength: 4,
                validator: (v) => v!.length < 4 ? 'Informe 4 dígitos' : null,
              ),
              TextFormField(
                controller: _limitController,
                decoration: const InputDecoration(
                  labelText: 'Limite Total (R\$)',
                  hintText: '0,00',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  CurrencyInputFormatter(), // Aplica a nossa máscara mágica aqui!
                ],
                validator: (v) => v!.isEmpty || v == '0,00' ? 'Informe o valor' : null,
              ),
              const SizedBox(height: 12),
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
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                hint: const Text('Conta para débito da fatura'),
                items: _accounts.map((acc) => DropdownMenuItem(value: acc.id, child: Text(acc.name))).toList(),
                onChanged: (val) => setState(() => _selectedAccountId = val),
                validator: (v) => v == null ? 'Selecione uma conta' : null,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                child: const Text('Cadastrar Cartão'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    // Remove tudo que não for número
    String numericString = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (numericString.isEmpty) {
      return const TextEditingValue(text: '', selection: TextSelection.collapsed(offset: 0));
    }

    // Converte para decimal (ex: digitou 123 -> vira 1.23)
    double value = double.parse(numericString) / 100;

    // Formata com 2 casas decimais e troca o ponto nativo por vírgula
    String newText = value.toStringAsFixed(2).replaceAll('.', ',');

    // Adiciona o separador de milhares (ponto)
    RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    List<String> parts = newText.split(',');
    parts[0] = parts[0].replaceAllMapped(reg, (Match match) => '${match[1]}.');
    newText = parts.join(',');

    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}
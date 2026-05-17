import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../database/database_helper.dart';
import '../models/account_model.dart';

class AccountFormPage extends StatefulWidget {
  final Account? account;
  const AccountFormPage({super.key, this.account});

  @override
  State<AccountFormPage> createState() => _AccountFormPageState();
}

class _AccountFormPageState extends State<AccountFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _balanceController = TextEditingController();
  String _selectedType = 'corrente';

  @override
  void initState() {
    super.initState();
    if (widget.account != null) {
      _nameController.text = widget.account!.name;
      // Aplica a formatação visual ao carregar para edição
      _balanceController.text = widget.account!.balance.toStringAsFixed(2).replaceAll('.', ',');
      _selectedType = widget.account!.type;
    }
  }

  void _save() async {
    if (_formKey.currentState!.validate()) {
      // Limpa a máscara para salvar no banco
      String cleanBalance = _balanceController.text.replaceAll('.', '').replaceAll(',', '.');

      final account = Account(
        id: widget.account?.id,
        name: _nameController.text.trim(),
        type: _selectedType,
        balance: double.parse(cleanBalance),
        userId: 1,
      );

      if (widget.account == null) {
        await DatabaseHelper.instance.createAccount(account);
      } else {
        await DatabaseHelper.instance.updateAccount(account);
      }
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.account == null ? 'Nova Conta' : 'Editar Conta')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nome da Instituição (Ex: Nubank)'),
                validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedType,
                items: ['corrente', 'poupanca', 'investimento', 'carteira']
                    .map((t) => DropdownMenuItem(value: t, child: Text(t.toUpperCase())))
                    .toList(),
                onChanged: (val) => setState(() => _selectedType = val!),
                decoration: const InputDecoration(labelText: 'Tipo de Conta'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _balanceController,
                decoration: const InputDecoration(labelText: 'Saldo Inicial (R\$)'),
                keyboardType: TextInputType.number,
                inputFormatters: [CurrencyInputFormatter()],
                validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _save,
                  child: const Text('Salvar Conta'),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

// Classe de Máscara incluída no mesmo arquivo para facilitar
class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    String numericString = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (numericString.isEmpty) return const TextEditingValue(text: '', selection: TextSelection.collapsed(offset: 0));
    double value = double.parse(numericString) / 100;
    String newText = value.toStringAsFixed(2).replaceAll('.', ',');
    RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    List<String> parts = newText.split(',');
    parts[0] = parts[0].replaceAllMapped(reg, (Match match) => '${match[1]}.');
    newText = parts.join(',');
    return TextEditingValue(text: newText, selection: TextSelection.collapsed(offset: newText.length));
  }
}
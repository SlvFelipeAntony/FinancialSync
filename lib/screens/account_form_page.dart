import 'package:flutter/material.dart';
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
      _balanceController.text = widget.account!.balance.toString();
      _selectedType = widget.account!.type;
    }
  }

  void _save() async {
    if (_formKey.currentState!.validate()) {
      final account = Account(
        id: widget.account?.id,
        name: _nameController.text,
        type: _selectedType,
        balance: double.parse(_balanceController.text),
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nome da Instituição'),
                validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
              ),
              DropdownButtonFormField<String>(
                value: _selectedType,
                items: ['corrente', 'poupanca', 'investimento', 'carteira']
                    .map((t) => DropdownMenuItem(value: t, child: Text(t.toUpperCase())))
                    .toList(),
                onChanged: (val) => setState(() => _selectedType = val!),
                decoration: const InputDecoration(labelText: 'Tipo'),
              ),
              TextFormField(
                controller: _balanceController,
                decoration: const InputDecoration(labelText: 'Saldo Inicial'),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _save,
                child: const Text('Salvar Conta'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
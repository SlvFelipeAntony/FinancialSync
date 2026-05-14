import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/account_model.dart';

class AccountFormPage extends StatefulWidget {
  final Account? account; // Se passado, a página entra em modo de edição
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
        userId: 1, // Usuário padrão para o projeto acadêmico
      );

      if (widget.account == null) {
        await DatabaseHelper.instance.createAccount(account);
      } else {
        await DatabaseHelper.instance.updateAccount(account);
      }

      if (mounted) Navigator.pop(context, true);
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
                decoration: const InputDecoration(labelText: 'Nome da Conta (Ex: Nubank, Carteira)'),
                validator: (v) => v!.isEmpty ? 'Informe um nome' : null,
              ),
              DropdownButtonFormField<String>(
                value: _selectedType,
                items: const [
                  DropdownMenuItem(value: 'corrente', child: Text('Conta Corrente')),
                  DropdownMenuItem(value: 'poupanca', child: Text('Poupança')),
                  DropdownMenuItem(value: 'investimento', child: Text('Investimento')),
                  DropdownMenuItem(value: 'carteira', child: Text('Dinheiro em Espécie')),
                ],
                onChanged: (val) => setState(() => _selectedType = val!),
                decoration: const InputDecoration(labelText: 'Tipo de Conta'),
              ),
              TextFormField(
                controller: _balanceController,
                decoration: const InputDecoration(labelText: 'Saldo Inicial (R\$)'),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? 'Informe o saldo' : null,
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                child: const Text('Confirmar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
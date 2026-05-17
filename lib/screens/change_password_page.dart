import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/user_model.dart';

class ChangePasswordPage extends StatefulWidget {
  final User user;
  const ChangePasswordPage({super.key, required this.user});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  void _changePassword() async {
    if (_formKey.currentState!.validate()) {
      if (_currentPasswordController.text != widget.user.password) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Senha atual incorreta!')),
        );
        return;
      }

      await DatabaseHelper.instance.updatePassword(
        widget.user.id!,
        _newPasswordController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Senha alterada com sucesso!')),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Alterar Senha')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _currentPasswordController,
                decoration: const InputDecoration(labelText: 'Senha Atual'),
                obscureText: true,
                validator: (v) => v!.isEmpty ? 'Informe a senha atual' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _newPasswordController,
                decoration: const InputDecoration(labelText: 'Nova Senha'),
                obscureText: true,
                validator: (v) => v!.length < 6 ? 'A senha deve ter no mínimo 6 caracteres' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmPasswordController,
                decoration: const InputDecoration(labelText: 'Confirmar Nova Senha'),
                obscureText: true,
                validator: (v) {
                  if (v != _newPasswordController.text) {
                    return 'As senhas não coincidem';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _changePassword,
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                child: const Text('Atualizar Senha'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
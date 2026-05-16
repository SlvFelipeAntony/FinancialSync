import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/user_model.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passController = TextEditingController();

  void _register() async {
    if (_formKey.currentState!.validate()) {
      try {
        final user = User(
          name: _nameController.text,
          email: _emailController.text,
          password: _passController.text,
        );

        final id = await DatabaseHelper.instance.createUser(user);
        print("Usuário registrado com ID: $id"); // Debug

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Conta criada!')));
          Navigator.pop(context);
        }
      } catch (e) {
        print("ERRO NO REGISTRO: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Criar Conta')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(controller: _nameController, decoration: const InputDecoration(labelText: 'Nome')),
              TextFormField(controller: _emailController, decoration: const InputDecoration(labelText: 'E-mail')),
              TextFormField(controller: _passController, decoration: const InputDecoration(labelText: 'Palavra-passe'), obscureText: true),
              const SizedBox(height: 30),
              ElevatedButton(onPressed: _register, child: const Text('Registar')),
            ],
          ),
        ),
      ),
    );
  }
}
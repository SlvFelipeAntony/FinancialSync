import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import 'home_page.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passController = TextEditingController();

  void _doLogin() async {
    try {
      print("Tentando login com: ${_emailController.text}"); // Debug
      final user = await DatabaseHelper.instance.login(_emailController.text, _passController.text);

      if (user != null) {
        print("Login bem-sucedido! ID: ${user.id}"); // Debug
        if (mounted) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomePage()));
        }
      } else {
        print("Usuário não encontrado ou senha incorreta."); // Debug
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('E-mail ou senha incorretos!')));
        }
      }
    } catch (e) {
      print("ERRO NO LOGIN: $e"); // Isso vai te dizer se a tabela não existe
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.sync_alt, size: 80, color: Colors.blueAccent),
            const Text('FinancialSync', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 40),
            TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'E-mail')),
            TextField(controller: _passController, decoration: const InputDecoration(labelText: 'Palavra-passe'), obscureText: true),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _doLogin, child: const Text('Entrar')),
            TextButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterPage())),
              child: const Text('Não tem conta? Registe-se'),
            ),
          ],
        ),
      ),
    );
  }
}
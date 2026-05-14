import 'package:flutter/material.dart';
import 'screens/login_page.dart';
// Note: As outras telas são importadas dentro das páginas de navegação,
// então a main só precisa conhecer a porta de entrada.

void main() {
  // Garante que as ligações do Flutter estejam prontas antes de iniciar o banco de dados
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FinancialSyncApp());
}

class FinancialSyncApp extends StatelessWidget {
  const FinancialSyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FinancialSync',
      debugShowCheckedModeBanner: false,

      // Definição do Tema do Aplicativo (Material 3)
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blueAccent,
          brightness: Brightness.light,
        ),
        // Personalização global de botões
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        // Personalização global de campos de texto
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Colors.grey[50],
        ),
      ),

      // O aplicativo inicia na tela de Login para cumprir o requisito RF01
      home: const LoginPage(),
    );
  }
}
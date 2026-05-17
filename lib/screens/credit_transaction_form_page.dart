import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart'; // Máscara de Moeda (Currency Mask)
import '../database/database_helper.dart';
import '../models/credit_transaction_model.dart';
import '../models/credit_card_model.dart';
import '../models/category_model.dart'; // Importação adicionada

class CreditTransactionFormPage extends StatefulWidget {
  const CreditTransactionFormPage({super.key});

  @override
  State<CreditTransactionFormPage> createState() => _CreditTransactionFormPageState();
}

class _CreditTransactionFormPageState extends State<CreditTransactionFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _descController = TextEditingController();
  final _valueController = TextEditingController();
  final _installmentController = TextEditingController(text: '1');

  String _selectedType = 'saida';
  int? _selectedCardId;
  String? _selectedCategory; // Variável para a categoria selecionada

  List<CreditCard> _cards = [];
  List<CategoryModel> _categories = []; // Lista do banco

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  void _loadInitialData() async {
    final cards = await DatabaseHelper.instance.readAllCreditCards();
    final categories = await DatabaseHelper.instance.readAllCategories();
    setState(() {
      _cards = cards;
      _categories = categories;
    });
  }

  void _save() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedCardId == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecione um cartão')));
        return;
      }

      String cleanValue = _valueController.text.replaceAll('.', '').replaceAll(',', '.');

      final trans = CreditTransaction(
        type: _selectedType,
        description: _descController.text,
        value: double.parse(cleanValue),
        category: _selectedCategory!, // Salva o nome da categoria vinculada
        date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
        installment: int.parse(_installmentController.text),
        creditCardId: _selectedCardId!,
      );

      await DatabaseHelper.instance.insertCreditTransaction(trans);
      if (mounted) Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gasto no Cartão')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'saida', label: Text('Compra'), icon: Icon(Icons.shopping_cart)),
                  ButtonSegment(value: 'entrada', label: Text('Estorno'), icon: Icon(Icons.assignment_return)),
                ],
                selected: {_selectedType},
                onSelectionChanged: (val) => setState(() => _selectedType = val.first),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(labelText: 'Descrição (Ex: Supermercado)'),
                validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _valueController,
                      decoration: const InputDecoration(
                        labelText: 'Valor (R\$)',
                        hintText: '0,00',
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        CurrencyInputFormatter(), // Aplica a nossa máscara mágica aqui!
                      ],
                      validator: (v) => v!.isEmpty || v == '0,00' ? 'Informe o valor' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _installmentController,
                      decoration: const InputDecoration(labelText: 'Parcelas'),
                      keyboardType: TextInputType.number,
                      validator: (v) => int.tryParse(v!) == null ? 'Inválido' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // NOVO: Dropdown de Categorias dinâmicas
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                hint: const Text('Selecione a Categoria'),
                items: _categories.map((cat) => DropdownMenuItem(
                  value: cat.name,
                  child: Text(cat.name),
                )).toList(),
                onChanged: (val) => setState(() => _selectedCategory = val),
                validator: (v) => v == null ? 'Obrigatório' : null,
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<int>(
                value: _selectedCardId,
                hint: const Text('Selecione o Cartão'),
                items: _cards.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                onChanged: (val) => setState(() => _selectedCardId = val),
                validator: (v) => v == null ? 'Obrigatório' : null,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _save,
                  child: const Text('Confirmar na Fatura'),
                ),
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
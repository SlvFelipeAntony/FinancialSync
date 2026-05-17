import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/credit_transaction_model.dart';
import '../models/credit_card_model.dart';
import '../models/category_model.dart';

class CreditTransactionFormPage extends StatefulWidget {
  final CreditTransaction? transaction; // NOVO: Aceita transação para edição
  const CreditTransactionFormPage({super.key, this.transaction});

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
  String? _selectedCategory;
  DateTime _selectedDate = DateTime.now();

  List<CreditCard> _cards = [];
  List<CategoryModel> _categories = [];

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  @override
  void initState() {
    super.initState();
    _loadInitialData();

    // Preenche os dados se for edição
    if (widget.transaction != null) {
      final t = widget.transaction!;
      _descController.text = t.description;
      _installmentController.text = t.installment.toString();
      _selectedType = t.type;
      _selectedCategory = t.category;
      _selectedCardId = t.creditCardId;
      _selectedDate = DateTime.parse(t.date);

      // 1. Carrega o valor da parcela temporariamente (para compras à vista ou delay rápido)
      _valueController.text = t.value.toStringAsFixed(2).replaceAll('.', ',');

      // 2. Se for parcelado, busca o valor TOTAL e atualiza o campo
      if (t.installment > 1) {
        _loadTotalValue(t);
      }
    }
  }

  // Método assíncrono para buscar o valor cheio da compra
  void _loadTotalValue(CreditTransaction t) async {
    double total = await DatabaseHelper.instance.getCreditTransactionGroupTotal(t);
    if (mounted) {
      setState(() {
        // Atualiza o campo com a máscara de moeda correta
        _valueController.text = total.toStringAsFixed(2).replaceAll('.', ',');
      });
    }
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
        id: widget.transaction?.id,
        type: _selectedType,
        description: _descController.text.trim(),
        value: double.parse(cleanValue),
        category: _selectedCategory!,
        date: DateFormat('yyyy-MM-dd').format(_selectedDate),
        installment: _selectedType == 'saida' ? int.parse(_installmentController.text) : 1, // Força 1 se for estorno
        creditCardId: _selectedCardId!,
      );

      if (widget.transaction == null) {
        await DatabaseHelper.instance.insertCreditTransaction(trans);
      } else {
        await DatabaseHelper.instance.updateCreditTransaction(trans, widget.transaction!);
      }

      if (mounted) Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.transaction == null ? 'Gasto no Cartão' : 'Editar Gasto')),
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
                      decoration: const InputDecoration(labelText: 'Valor Total (R\$)'),
                      keyboardType: TextInputType.number,
                      inputFormatters: [CurrencyInputFormatter()],
                      validator: (v) => v!.isEmpty || v == '0,00' ? 'Obrigatório' : null,
                    ),
                  ),
                  // Oculta o campo de parcelas se for Estorno (entrada)
                  if (_selectedType == 'saida') ...[
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
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_today),
                  label: Text('Data da Compra: ${DateFormat('dd/MM/yyyy').format(_selectedDate)}'),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                hint: const Text('Selecione a Categoria'),
                items: _categories.map((cat) => DropdownMenuItem(value: cat.name, child: Text(cat.name))).toList(),
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
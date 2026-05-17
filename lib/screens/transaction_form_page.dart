import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import '../database/database_helper.dart';
import '../models/transaction_model.dart';
import '../models/account_model.dart';
import '../models/category_model.dart';

class TransactionFormPage extends StatefulWidget {
  final AccountTransaction? transaction; // Adicione este parâmetro opcional
  const TransactionFormPage({super.key, this.transaction});

  @override
  State<TransactionFormPage> createState() => _TransactionFormPageState();
}

class _TransactionFormPageState extends State<TransactionFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _descController = TextEditingController();
  final _valueController = TextEditingController();

  // Novos controladores para os campos opcionais
  final _appController = TextEditingController();
  final _linkController = TextEditingController();

  String _selectedType = 'saida';
  int? _selectedAccountId;
  String? _selectedCategory;

  // Variáveis para controlar a Data e a Hora escolhidas pelo usuário
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  List<Account> _accounts = [];
  List<CategoryModel> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadInitialData();

    if (widget.transaction != null) {
      final t = widget.transaction!;
      _descController.text = t.description;
      _valueController.text = t.value.toStringAsFixed(2).replaceAll('.', ',');
      _selectedType = t.type;
      _selectedCategory = t.category;
      _selectedAccountId = t.accountsId;
      _selectedDate = DateTime.parse(t.date);
      _appController.text = t.application ?? '';
      _linkController.text = t.link ?? '';

      // --- ADICIONE ESTE BLOCO PARA CARREGAR A HORA ---
      if (t.time != null && t.time!.isNotEmpty) {
        final parts = t.time!.split(':');
        _selectedTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      }
    }

    // Se receber uma transação externa, preenche o formulário em modo EDIÇÃO
    if (widget.transaction != null) {
      final t = widget.transaction!;
      _descController.text = t.description;
      // Formata o valor bruto double para exibição na máscara customizada
      _valueController.text = t.value.toStringAsFixed(2).replaceAll('.', ',');
      _selectedType = t.type;
      _selectedCategory = t.category;
      _selectedAccountId = t.accountsId;
      _selectedDate = DateTime.parse(t.date);
      _appController.text = t.application ?? '';
      _linkController.text = t.link ?? '';
    }
  }

  void _loadInitialData() async {
    final accounts = await DatabaseHelper.instance.readAllAccounts(1);
    final categories = await DatabaseHelper.instance.readAllCategories();
    setState(() {
      _accounts = accounts;
      _categories = categories;
    });
  }

  // Função para abrir o calendário nativo
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

  // Função para abrir o relógio nativo
  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  void _save() async {
    if (_formKey.currentState!.validate()) {
      String cleanValue = _valueController.text.replaceAll('.', '').replaceAll(',', '.');
      final formattedTime = '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}:00';

      final trans = AccountTransaction(
        id: widget.transaction?.id,
        type: _selectedType,
        description: _descController.text.trim(),
        value: double.parse(cleanValue),
        category: _selectedCategory!,
        date: DateFormat('yyyy-MM-dd').format(_selectedDate),
        time: formattedTime, // <-- MUDE PARA ISTO (removeu o widget.transaction?.time)
        application: _appController.text.isEmpty ? null : _appController.text.trim(),
        link: _linkController.text.isEmpty ? null : _linkController.text.trim(),
        accountsId: _selectedAccountId!,
      );

      if (widget.transaction == null) {
        // Nova inserção normal
        await DatabaseHelper.instance.insertTransaction(trans);
      } else {
        // Atualização redefinindo impactos anteriores
        await DatabaseHelper.instance.updateTransaction(trans, widget.transaction!);
      }

      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nova Movimentação')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'entrada', label: Text('Receita'), icon: Icon(Icons.add)),
                  ButtonSegment(value: 'saida', label: Text('Despesa'), icon: Icon(Icons.remove)),
                ],
                selected: {_selectedType},
                onSelectionChanged: (val) => setState(() => _selectedType = val.first),
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(labelText: 'Descrição (Ex: Padaria)'),
                validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _valueController,
                decoration: const InputDecoration(
                  labelText: 'Valor (R\$)',
                  hintText: '0,00',
                ),
                keyboardType: TextInputType.number, // Mantém o teclado numérico
                inputFormatters: [
                  CurrencyInputFormatter(), // Aplica a nossa máscara mágica aqui!
                ],
                validator: (v) => v!.isEmpty || v == '0,00' ? 'Informe o valor' : null,
              ),
              const SizedBox(height: 16),

              // Linha com botões para escolher Data e Hora
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickDate,
                      icon: const Icon(Icons.calendar_today),
                      label: Text(DateFormat('dd/MM/yyyy').format(_selectedDate)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickTime,
                      icon: const Icon(Icons.access_time),
                      label: Text(_selectedTime.format(context)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

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
                value: _selectedAccountId,
                hint: const Text('Selecione a Conta de Origem/Destino'),
                items: _accounts.map((acc) => DropdownMenuItem(
                  value: acc.id,
                  child: Text(acc.name),
                )).toList(),
                onChanged: (val) => setState(() => _selectedAccountId = val),
                validator: (v) => v == null ? 'Obrigatório' : null,
              ),

              const Divider(height: 40),
              const Text('Informações Adicionais', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

              // Campos novos opcionais
              TextFormField(
                controller: _appController,
                decoration: const InputDecoration(
                  labelText: 'Aplicação / Instituição (Opcional)',
                  hintText: 'Ex: iFood, Uber, Amazon',
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _linkController,
                decoration: const InputDecoration(
                  labelText: 'Link / Comprovante (Opcional)',
                  hintText: 'https://...',
                ),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _save,
                  child: const Text('Confirmar Transação'),
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
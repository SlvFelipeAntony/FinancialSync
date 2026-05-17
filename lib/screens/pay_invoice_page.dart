import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/credit_card_model.dart';
import '../models/account_model.dart';

class PayInvoicePage extends StatefulWidget {
  final CreditCard card;
  final double invoiceTotal;

  const PayInvoicePage({super.key, required this.card, required this.invoiceTotal});

  @override
  State<PayInvoicePage> createState() => _PayInvoicePageState();
}

class _PayInvoicePageState extends State<PayInvoicePage> {
  final _formKey = GlobalKey<FormState>();
  int? _selectedAccountId;
  List<Account> _accounts = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  void _loadAccounts() async {
    final accounts = await DatabaseHelper.instance.readAllAccounts(1);
    setState(() => _accounts = accounts);
  }

  void _confirmPayment() async {
    if (_formKey.currentState!.validate() && _selectedAccountId != null) {
      setState(() => _isLoading = true);
      try {
        await DatabaseHelper.instance.payInvoice(
          widget.card.id!,
          _selectedAccountId!,
          widget.invoiceTotal,
          widget.card.name,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Fatura liquidada com sucesso!')),
          );
          Navigator.pop(context, true); // Retorna true para atualizar a fatura visualmente
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao processar pagamento: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pagar Fatura')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                color: Colors.blueGrey[50],
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total da Fatura:',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      Text(
                        'R\$ ${widget.invoiceTotal.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.red),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Conta para débito:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                hint: const Text('Selecione a Conta Bancária'),
                items: _accounts.map((acc) => DropdownMenuItem(
                  value: acc.id,
                  child: Text('${acc.name} (Saldo: R\$ ${acc.balance.toStringAsFixed(2)})'),
                )).toList(),
                onChanged: (val) => setState(() => _selectedAccountId = val),
                validator: (v) => v == null ? 'Obrigatório' : null,
              ),
              const SizedBox(height: 40),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _confirmPayment,
                  child: const Text('Confirmar Pagamento'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
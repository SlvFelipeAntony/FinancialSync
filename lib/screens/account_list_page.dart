import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/account_model.dart';
import 'account_form_page.dart';

class AccountListPage extends StatefulWidget {
  const AccountListPage({super.key});

  @override
  State<AccountListPage> createState() => _AccountListPageState();
}

class _AccountListPageState extends State<AccountListPage> {
  late Future<List<Account>> _accountsFuture;

  @override
  void initState() {
    super.initState();
    _refreshAccounts();
  }

  void _refreshAccounts() {
    setState(() {
      _accountsFuture = DatabaseHelper.instance.readAllAccounts(1);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Minhas Contas')),
      body: FutureBuilder<List<Account>>(
        future: _accountsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Nenhuma conta cadastrada.'));
          }

          final accounts = snapshot.data!;
          return ListView.builder(
            itemCount: accounts.length,
            itemBuilder: (context, index) {
              final acc = accounts[index];
              return ListTile(
                leading: const Icon(Icons.account_balance, color: Colors.blue),
                title: Text(acc.name),
                subtitle: Text(acc.type.toUpperCase()),
                trailing: Text('R\$ ${acc.balance.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AccountFormPage(account: acc)),
                  );
                  if (result == true) _refreshAccounts();
                },
                onLongPress: () {
                  // Opção para deletar
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Excluir conta?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
                        TextButton(onPressed: () async {
                          await DatabaseHelper.instance.deleteAccount(acc.id!);
                          Navigator.pop(context);
                          _refreshAccounts();
                        }, child: const Text('Excluir')),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'add_account',
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AccountFormPage()),
          );
          if (result == true) _refreshAccounts();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
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
    _refresh();
  }

  void _refresh() {
    setState(() {
      _accountsFuture = DatabaseHelper.instance.readAllAccounts(1); // Usando ID 1 para teste
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<Account>>(
        future: DatabaseHelper.instance.readAllAccounts(1),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final accounts = snapshot.data!;

          return ListView.builder(
            itemCount: accounts.length,
            itemBuilder: (context, index) {
              final acc = accounts[index];
              return ListTile(
                leading: const Icon(Icons.account_balance_wallet, color: Colors.blueAccent),
                title: Text(acc.name),
                subtitle: Text(acc.type.toUpperCase()),
                trailing: Text('R\$ ${acc.balance.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AccountFormPage(account: acc))
                ).then((_) => _refresh()),
              );
            },
          );
        },
      ),
    );
  }
}
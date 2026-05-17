import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/account_model.dart';
import 'account_form_page.dart';
import 'credit_card_list_page.dart'; // Importação do seu arquivo de cartões

class AccountListPage extends StatefulWidget {
  const AccountListPage({super.key});

  @override
  State<AccountListPage> createState() => _AccountListPageState();
}

class _AccountListPageState extends State<AccountListPage> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: const TabBar(
              tabs: [
                Tab(icon: Icon(Icons.account_balance_wallet), text: "Contas e Dinheiro"),
                Tab(icon: Icon(Icons.credit_card), text: "Cartões de Crédito"),
              ],
            ),
          ),
        ),
        body: TabBarView(
          children: [
            // ABA 1: Lista de Contas Bancárias
            Scaffold(
              body: FutureBuilder<List<Account>>(
                future: DatabaseHelper.instance.readAllAccounts(1),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  final accounts = snapshot.data!;
                  if (accounts.isEmpty) return const Center(child: Text('Nenhuma conta cadastrada.'));

                  return ListView.builder(
                    itemCount: accounts.length,
                    itemBuilder: (context, index) {
                      final acc = accounts[index];
                      return ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.monetization_on)),
                        title: Text(acc.name),
                        subtitle: Text(acc.type.toUpperCase()),
                        trailing: Text('R\$ ${acc.balance.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => AccountFormPage(account: acc))
                        ).then((_) => setState(() {})),
                      );
                    },
                  );
                },
              ),
              floatingActionButton: FloatingActionButton(
                heroTag: 'fab_accounts',
                onPressed: () => Navigator.push(
                    context, MaterialPageRoute(builder: (context) => const AccountFormPage())
                ).then((_) => setState(() {})),
                child: const Icon(Icons.add),
              ),
            ),

            // ABA 2: Lista de Cartões de Crédito (Chama o arquivo existente)
            const CreditCardListPage(),
          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vfinance/app/vfinance_scope.dart';
import 'package:vfinance/data/local/app_database.dart';
import 'package:vfinance/data/local/finance_local_repository.dart';
import 'package:vfinance/presentation/formatting/amount_format.dart';

/// Lists accounts and balances.
class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  FinanceLocalRepository? _repositoryForStreams;
  Stream<List<Account>>? _accountsStream;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final FinanceLocalRepository repo = VfinanceScope.of(context);
    if (_repositoryForStreams != repo) {
      _repositoryForStreams = repo;
      _accountsStream = repo.watchAccounts();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Contas')),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_accounts',
        onPressed: () => context.push('/accounts/add'),
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<Account>>(
        stream: _accountsStream!,
        builder: (BuildContext context, AsyncSnapshot<List<Account>> snap) {
          if (snap.hasError) {
            return Center(child: Text('${snap.error}'));
          }
          final List<Account> rows = snap.data ?? <Account>[];
          if (rows.isEmpty) {
            return const Center(
              child: Text('Nenhuma conta. Toque em + para criar.'),
            );
          }
          return ListView.separated(
            itemCount: rows.length,
            separatorBuilder: (BuildContext context, int _) =>
                const Divider(height: 1),
            itemBuilder: (BuildContext context, int index) {
              final Account a = rows[index];
              return ListTile(
                title: Text(a.name),
                subtitle: Text(a.type),
                trailing: Text(
                  formatCents(a.balanceInCents),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              );
            },
          );
        },
      ),
    );
  }
}

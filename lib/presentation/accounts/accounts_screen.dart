import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vfinance/app/vfinance_scope.dart';
import 'package:vfinance/data/local/app_database.dart';
import 'package:vfinance/data/local/finance_local_repository.dart';
import 'package:vfinance/domain/delete_blocked_exceptions.dart';
import 'package:vfinance/l10n/app_localizations.dart';
import 'package:vfinance/presentation/formatting/amount_format.dart';
import 'package:vfinance/presentation/l10n/transaction_labels.dart';

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

  Future<void> _confirmDeleteAccount(
    BuildContext context,
    Account account,
  ) async {
    final AppLocalizations l = AppLocalizations.of(context)!;
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: Text(l.deleteConfirmTitle),
        content: Text(l.deleteConfirmAccountBody),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.deleteAction),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) {
      return;
    }
    final FinanceLocalRepository repo = VfinanceScope.of(context);
    try {
      await repo.deleteAccount(account.id);
    } on AccountDeleteBlockedException {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l.errorDeleteAccountBlocked)));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l.errorWithMessage('$e'))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l.accountsTitle)),
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
            return Center(child: Text(l.accountsEmpty));
          }
          return ListView.separated(
            itemCount: rows.length,
            separatorBuilder: (BuildContext context, int _) =>
                const Divider(height: 1),
            itemBuilder: (BuildContext context, int index) {
              final Account a = rows[index];
              return ListTile(
                title: Text(a.name),
                subtitle: Text(labelAccountTypeStorage(l, a.type)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      formatCents(a.balanceInCents),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    PopupMenuButton<String>(
                      onSelected: (String value) {
                        if (value == 'edit') {
                          context.push('/accounts/edit/${a.id}');
                        }
                        if (value == 'delete') {
                          _confirmDeleteAccount(context, a);
                        }
                      },
                      itemBuilder: (BuildContext ctx) =>
                          <PopupMenuEntry<String>>[
                            PopupMenuItem<String>(
                              value: 'edit',
                              child: Text(l.menuEdit),
                            ),
                            PopupMenuItem<String>(
                              value: 'delete',
                              child: Text(l.menuDelete),
                            ),
                          ],
                    ),
                  ],
                ),
                onTap: () => context.push('/accounts/edit/${a.id}'),
              );
            },
          );
        },
      ),
    );
  }
}

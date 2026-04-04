import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:vfinance/app/vfinance_scope.dart';
import 'package:vfinance/data/local/app_database.dart';
import 'package:vfinance/data/local/finance_local_repository.dart';
import 'package:vfinance/domain/transaction_enums.dart';
import 'package:vfinance/l10n/app_localizations.dart';
import 'package:vfinance/domain/finance_calendar_date.dart';
import 'package:vfinance/presentation/formatting/amount_format.dart';
import 'package:vfinance/presentation/l10n/transaction_labels.dart';

/// Lists finance transactions (newest first).
class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  FinanceLocalRepository? _repositoryForStreams;
  Stream<List<FinanceTransaction>>? _transactionsStream;
  final DateFormat _dayFormat = DateFormat('dd/MM/yyyy');

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final FinanceLocalRepository repo = VfinanceScope.of(context);
    if (_repositoryForStreams != repo) {
      _repositoryForStreams = repo;
      _transactionsStream = repo.watchLedgerFinanceTransactions();
    }
  }

  Future<void> _confirmDeleteTransaction(
    BuildContext context,
    FinanceTransaction row,
  ) async {
    final AppLocalizations l = AppLocalizations.of(context)!;
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: Text(l.deleteConfirmTitle),
        content: Text(l.deleteConfirmTransactionBody),
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
      await repo.deleteFinanceTransaction(row.id);
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
      appBar: AppBar(title: Text(l.transactionsTitle)),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_transactions',
        onPressed: () => context.push('/transactions/add'),
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<FinanceTransaction>>(
        stream: _transactionsStream!,
        builder:
            (
              BuildContext context,
              AsyncSnapshot<List<FinanceTransaction>> snap,
            ) {
              if (snap.hasError) {
                return Center(child: Text('${snap.error}'));
              }
              final List<FinanceTransaction> rows =
                  snap.data ?? <FinanceTransaction>[];
              if (rows.isEmpty) {
                return Center(child: Text(l.transactionsEmpty));
              }
              return ListView.separated(
                itemCount: rows.length,
                separatorBuilder: (BuildContext context, int _) =>
                    const Divider(height: 1),
                itemBuilder: (BuildContext context, int index) {
                  final FinanceTransaction t = rows[index];
                  final DateTime civil = localCivilDateFromFinanceEpochMillis(
                    t.dateUtcMillis,
                  );
                  final DateTime d = DateTime(
                    civil.year,
                    civil.month,
                    civil.day,
                  );
                  final TransactionType tt = TransactionType.parseStorage(
                    t.transactionType,
                  );
                  final PaymentMethod pm = PaymentMethod.parseStorage(
                    t.paymentMethod,
                  );
                  return ListTile(
                    leading: const Icon(Icons.receipt_outlined),
                    title: Text(t.description),
                    subtitle: Text(
                      '${_dayFormat.format(d)} · '
                      '${labelTransactionType(l, tt)} · '
                      '${labelPaymentMethod(l, pm)} · ${t.category}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          formatCents(t.amountInCents),
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        PopupMenuButton<String>(
                          onSelected: (String value) {
                            if (value == 'edit') {
                              context.push('/transactions/edit/${t.id}');
                            }
                            if (value == 'delete') {
                              _confirmDeleteTransaction(context, t);
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
                    onTap: () => context.push('/transactions/edit/${t.id}'),
                  );
                },
              );
            },
      ),
    );
  }
}

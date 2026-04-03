import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:vfinance/app/vfinance_scope.dart';
import 'package:vfinance/data/local/app_database.dart';
import 'package:vfinance/data/local/finance_local_repository.dart';
import 'package:vfinance/domain/transaction_enums.dart';
import 'package:vfinance/presentation/formatting/amount_format.dart';

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
      _transactionsStream = repo.watchFinanceTransactions();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lançamentos')),
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
                return const Center(
                  child: Text('Nenhum lançamento. Toque em + para adicionar.'),
                );
              }
              return ListView.separated(
                itemCount: rows.length,
                separatorBuilder: (BuildContext context, int _) =>
                    const Divider(height: 1),
                itemBuilder: (BuildContext context, int index) {
                  final FinanceTransaction t = rows[index];
                  final DateTime d = DateTime.fromMillisecondsSinceEpoch(
                    t.dateUtcMillis,
                    isUtc: true,
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
                      '${tt.storageName} · ${pm.storageName} · ${t.category}',
                    ),
                    trailing: Text(
                      formatCents(t.amountInCents),
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  );
                },
              );
            },
      ),
    );
  }
}

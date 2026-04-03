import 'package:flutter/material.dart';
import 'package:vfinance/app/vfinance_scope.dart';
import 'package:vfinance/data/local/app_database.dart';
import 'package:vfinance/data/local/finance_local_repository.dart';
import 'package:vfinance/domain/balance_rules.dart';
import 'package:vfinance/domain/invoice_rules.dart';
import 'package:vfinance/presentation/formatting/amount_format.dart';

/// Dashboard with total balance (accounts − open unpaid invoices).
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  FinanceLocalRepository? _repositoryForStreams;
  Stream<List<Account>>? _accountsStream;
  Stream<List<Invoice>>? _invoicesStream;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final FinanceLocalRepository repo = VfinanceScope.of(context);
    if (_repositoryForStreams != repo) {
      _repositoryForStreams = repo;
      _accountsStream = repo.watchAccounts();
      _invoicesStream = repo.watchInvoices();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Stream<List<Account>> accountsStream = _accountsStream!;
    final Stream<List<Invoice>> invoicesStream = _invoicesStream!;
    return Scaffold(
      appBar: AppBar(title: const Text('Início')),
      body: StreamBuilder<List<Account>>(
        stream: accountsStream,
        builder: (BuildContext context, AsyncSnapshot<List<Account>> snapA) {
          if (snapA.hasError) {
            return _ErrorMessage(message: '${snapA.error}');
          }
          return StreamBuilder<List<Invoice>>(
            stream: invoicesStream,
            builder:
                (BuildContext context, AsyncSnapshot<List<Invoice>> snapI) {
                  if (snapI.hasError) {
                    return _ErrorMessage(message: '${snapI.error}');
                  }
                  final List<Account> accounts = snapA.data ?? <Account>[];
                  final List<Invoice> invoices = snapI.data ?? <Invoice>[];
                  final Iterable<OpenInvoiceBalanceInput> open =
                      openInvoiceBalanceInputsForTotal(
                        invoices: invoices.map(
                          (Invoice i) => InvoiceBalanceDescriptor(
                            totalInCents: i.totalInCents,
                            adjustedTotalInCents: i.adjustedTotalInCents,
                            isPaid: i.isPaid,
                          ),
                        ),
                      );
                  final int totalCents = computeTotalUserBalance(
                    accountBalancesInCents: accounts.map(
                      (Account a) => a.balanceInCents,
                    ),
                    openInvoices: open,
                  );
                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: <Widget>[
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                'Saldo total',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                formatCents(totalCents),
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Contas menos faturas em aberto (não pagas).',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text('Resumo', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Text(
                        '${accounts.length} conta(s) · '
                        '${invoices.where((Invoice i) => !i.isPaid).length} '
                        'fatura(s) em aberto',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  );
                },
          );
        },
      ),
    );
  }
}

class _ErrorMessage extends StatelessWidget {
  const _ErrorMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(message, textAlign: TextAlign.center),
      ),
    );
  }
}

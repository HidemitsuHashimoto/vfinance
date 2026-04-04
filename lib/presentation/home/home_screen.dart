import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:vfinance/app/vfinance_scope.dart';
import 'package:vfinance/data/local/app_database.dart';
import 'package:vfinance/data/local/finance_local_repository.dart';
import 'package:vfinance/data/local/pay_cycle_anchor_store.dart';
import 'package:vfinance/domain/balance_period_rules.dart';
import 'package:vfinance/domain/balance_rules.dart';
import 'package:vfinance/l10n/app_localizations.dart';
import 'package:vfinance/presentation/formatting/amount_format.dart';

/// Dashboard: Paycheck Planning — one balance block per configured pay day.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  FinanceLocalRepository? _repositoryForStreams;
  Stream<List<Account>>? _accountsStream;
  Stream<List<Invoice>>? _invoicesStream;
  Stream<List<CreditCard>>? _cardsStream;
  Stream<List<FinanceTransaction>>? _transactionsStream;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final FinanceLocalRepository repo = VfinanceScope.of(context);
    if (_repositoryForStreams != repo) {
      _repositoryForStreams = repo;
      _accountsStream = repo.watchAccounts();
      _invoicesStream = repo.watchInvoices();
      _cardsStream = repo.watchCreditCards();
      _transactionsStream = repo.watchFinanceTransactions();
    }
  }

  Future<void> _openPayCycleDialog(BuildContext context) async {
    final PayCycleAnchorStore store = VfinanceScope.payCycleAnchorsOf(context);
    await showDialog<void>(
      context: context,
      builder: (BuildContext ctx) => _PayCycleAnchorsDialog(
        initialDays: store.readAnchorDays(),
        store: store,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context)!;
    final ThemeData theme = Theme.of(context);
    final PayCycleAnchorStore anchors = VfinanceScope.payCycleAnchorsOf(
      context,
    );
    final List<int> anchorDays = anchors.readAnchorDays();
    return Scaffold(
      appBar: AppBar(
        title: Text(l.navHome),
        actions: <Widget>[
          IconButton(
            tooltip: l.homePaycheckConfigureTooltip,
            icon: const Icon(Icons.calendar_month_outlined),
            onPressed: () => _openPayCycleDialog(context),
          ),
        ],
      ),
      body: StreamBuilder<List<Account>>(
        stream: _accountsStream!,
        builder: (BuildContext context, AsyncSnapshot<List<Account>> snapA) {
          if (snapA.hasError) {
            return _ErrorMessage(message: '${snapA.error}');
          }
          return StreamBuilder<List<Invoice>>(
            stream: _invoicesStream!,
            builder:
                (BuildContext context, AsyncSnapshot<List<Invoice>> snapI) {
                  if (snapI.hasError) {
                    return _ErrorMessage(message: '${snapI.error}');
                  }
                  return StreamBuilder<List<CreditCard>>(
                    stream: _cardsStream!,
                    builder:
                        (
                          BuildContext context,
                          AsyncSnapshot<List<CreditCard>> snapC,
                        ) {
                          if (snapC.hasError) {
                            return _ErrorMessage(message: '${snapC.error}');
                          }
                          return StreamBuilder<List<FinanceTransaction>>(
                            stream: _transactionsStream!,
                            builder:
                                (
                                  BuildContext context,
                                  AsyncSnapshot<List<FinanceTransaction>> snapT,
                                ) {
                                  if (snapT.hasError) {
                                    return _ErrorMessage(
                                      message: '${snapT.error}',
                                    );
                                  }
                                  final List<Account> accounts =
                                      snapA.data ?? <Account>[];
                                  final List<Invoice> invoices =
                                      snapI.data ?? <Invoice>[];
                                  final List<CreditCard> cards =
                                      snapC.data ?? <CreditCard>[];
                                  final List<FinanceTransaction> transactions =
                                      snapT.data ?? <FinanceTransaction>[];
                                  if (anchorDays.isEmpty) {
                                    return _PaycheckEmptyState(
                                      l: l,
                                      theme: theme,
                                      onConfigure: () =>
                                          _openPayCycleDialog(context),
                                    );
                                  }
                                  final DateTime todayLocal = DateTime.now();
                                  final Map<int, CardDueDescriptor> cardById =
                                      <int, CardDueDescriptor>{
                                        for (final CreditCard c in cards)
                                          c.id: CardDueDescriptor(
                                            id: c.id,
                                            dueDay: c.dueDay,
                                          ),
                                      };
                                  final List<Widget> cardsWidgets = <Widget>[];
                                  for (final int anchorDay in anchorDays) {
                                    final (
                                      DateTime rangeStart,
                                      DateTime rangeEnd,
                                    ) = payCycleLocalBoundsForAnchorDay(
                                      todayLocal: todayLocal,
                                      anchorDay: anchorDay,
                                    );
                                    final List<OpenInvoiceBalanceInput>
                                    invoiceInputs =
                                        invoiceBalanceInputsDueInLocalRange(
                                          invoices: invoices.map(
                                            (Invoice i) => InvoiceCycleSnapshot(
                                              cardId: i.cardId,
                                              year: i.year,
                                              month: i.month,
                                              totalInCents: i.totalInCents,
                                              adjustedTotalInCents:
                                                  i.adjustedTotalInCents,
                                            ),
                                          ),
                                          cardById: cardById,
                                          rangeStartLocal: rangeStart,
                                          rangeEndLocal: rangeEnd,
                                        ).toList();
                                    final int totalCents =
                                        computeTotalUserBalance(
                                          accountBalancesInCents: accounts.map(
                                            (Account a) => a.balanceInCents,
                                          ),
                                          openInvoices: invoiceInputs,
                                        );
                                    final int invoicesDueCount =
                                        invoiceInputs.length;
                                    final ({
                                      int incomeCents,
                                      int immediateExpenseCents,
                                    })
                                    flow = summarizeCashflowInLocalRange(
                                      transactions: transactions.map(
                                        (FinanceTransaction t) =>
                                            TransactionTimelineRow(
                                              amountInCents: t.amountInCents,
                                              transactionTypeStorage:
                                                  t.transactionType,
                                              paymentMethodStorage:
                                                  t.paymentMethod,
                                              dateUtcMillis: t.dateUtcMillis,
                                            ),
                                      ),
                                      rangeStartLocal: rangeStart,
                                      rangeEndLocal: rangeEnd,
                                    );
                                    final String startLabel = DateFormat.yMd(
                                      'pt_BR',
                                    ).format(rangeStart);
                                    final String endLabel = DateFormat.yMd(
                                      'pt_BR',
                                    ).format(rangeEnd);
                                    if (cardsWidgets.isNotEmpty) {
                                      cardsWidgets.add(
                                        const SizedBox(height: 16),
                                      );
                                    }
                                    cardsWidgets.add(
                                      _PaycheckPeriodCard(
                                        l: l,
                                        theme: theme,
                                        anchorDay: anchorDay,
                                        intervalLabel: l.homePaycheckInterval(
                                          startLabel,
                                          endLabel,
                                        ),
                                        totalCents: totalCents,
                                        invoicesDueCount: invoicesDueCount,
                                        accountsCount: accounts.length,
                                        incomeCents: flow.incomeCents,
                                        immediateExpenseCents:
                                            flow.immediateExpenseCents,
                                      ),
                                    );
                                  }
                                  return ListView(
                                    padding: const EdgeInsets.all(16),
                                    children: cardsWidgets,
                                  );
                                },
                          );
                        },
                  );
                },
          );
        },
      ),
    );
  }
}

class _PaycheckEmptyState extends StatelessWidget {
  const _PaycheckEmptyState({
    required this.l,
    required this.theme,
    required this.onConfigure,
  });

  final AppLocalizations l;
  final ThemeData theme;
  final VoidCallback onConfigure;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              l.homePaycheckEmptyTitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              l.homePaycheckEmptyBody,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onConfigure,
              icon: const Icon(Icons.edit_calendar_outlined),
              label: Text(l.homePaycheckEmptyAction),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaycheckPeriodCard extends StatelessWidget {
  const _PaycheckPeriodCard({
    required this.l,
    required this.theme,
    required this.anchorDay,
    required this.intervalLabel,
    required this.totalCents,
    required this.invoicesDueCount,
    required this.accountsCount,
    required this.incomeCents,
    required this.immediateExpenseCents,
  });

  final AppLocalizations l;
  final ThemeData theme;
  final int anchorDay;
  final String intervalLabel;
  final int totalCents;
  final int invoicesDueCount;
  final int accountsCount;
  final int incomeCents;
  final int immediateExpenseCents;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              l.homePaycheckPeriodTitle(anchorDay),
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              intervalLabel,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l.homeTotalBalance,
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
              l.homePaycheckBalanceFootnote,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l.homePaycheckSummaryHeading,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '${l.homeAccountsCount(accountsCount)} · '
              '${l.homeInvoicesDueInPeriod(invoicesDueCount)}',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '${l.homePeriodIncome}: ${formatCents(incomeCents)}',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 4),
            Text(
              '${l.homePeriodImmediateExpenses}: '
              '${formatCents(immediateExpenseCents)}',
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _PayCycleAnchorsDialog extends StatefulWidget {
  const _PayCycleAnchorsDialog({
    required this.initialDays,
    required this.store,
  });

  final List<int> initialDays;
  final PayCycleAnchorStore store;

  @override
  State<_PayCycleAnchorsDialog> createState() => _PayCycleAnchorsDialogState();
}

class _PayCycleAnchorsDialogState extends State<_PayCycleAnchorsDialog> {
  late List<int> _draft;
  final TextEditingController _dayField = TextEditingController();
  String? _fieldError;

  @override
  void initState() {
    super.initState();
    _draft = List<int>.from(widget.initialDays)..sort();
  }

  @override
  void dispose() {
    _dayField.dispose();
    super.dispose();
  }

  void _tryAddDay(AppLocalizations l) {
    final int? parsed = int.tryParse(_dayField.text.trim());
    if (parsed == null || parsed < 1 || parsed > 31) {
      setState(() {
        _fieldError = l.daysInvalidRange;
      });
      return;
    }
    if (_draft.contains(parsed)) {
      setState(() {
        _fieldError = l.homePaycheckDialogDuplicateDay;
      });
      return;
    }
    setState(() {
      _draft.add(parsed);
      _draft.sort();
      _fieldError = null;
      _dayField.clear();
    });
  }

  Future<void> _saveAndClose(BuildContext context) async {
    await widget.store.setAnchorDays(_draft);
    if (context.mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l.homePaycheckDialogTitle),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                l.homePaycheckDialogBody,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _dayField,
                decoration: InputDecoration(
                  labelText: l.homePaycheckDialogDayLabel,
                  errorText: _fieldError,
                ),
                keyboardType: TextInputType.number,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly,
                ],
                onChanged: (_) {
                  if (_fieldError != null) {
                    setState(() => _fieldError = null);
                  }
                },
                onSubmitted: (_) => _tryAddDay(l),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => _tryAddDay(l),
                  child: Text(l.homePaycheckDialogAdd),
                ),
              ),
              if (_draft.isNotEmpty) const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  for (final int d in _draft)
                    InputChip(
                      label: Text('$d'),
                      onDeleted: () {
                        setState(() {
                          _draft.remove(d);
                        });
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l.commonCancel),
        ),
        FilledButton(
          onPressed: () => _saveAndClose(context),
          child: Text(l.commonSave),
        ),
      ],
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

import 'dart:math' show min;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:vfinance/app/vfinance_scope.dart';
import 'package:vfinance/data/local/app_database.dart';
import 'package:vfinance/data/local/finance_local_repository.dart';
import 'package:vfinance/domain/balance_period_rules.dart';
import 'package:vfinance/domain/delete_blocked_exceptions.dart';
import 'package:vfinance/domain/finance_calendar_date.dart';
import 'package:vfinance/domain/invoice_rules.dart';
import 'package:vfinance/domain/money.dart';
import 'package:vfinance/domain/transaction_enums.dart';
import 'package:vfinance/l10n/app_localizations.dart';
import 'package:vfinance/presentation/formatting/amount_format.dart';

/// Lists cards and their invoices; can add card or invoice rows.
class CardsScreen extends StatefulWidget {
  const CardsScreen({super.key});

  @override
  State<CardsScreen> createState() => _CardsScreenState();
}

class _CardsScreenState extends State<CardsScreen> {
  FinanceLocalRepository? _repositoryForStreams;
  late Stream<List<CreditCard>> _creditCardsStream;
  late Stream<List<Invoice>> _invoicesStream;
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

  /// Cycle month (invoice year/month) shown in lists and the month navigator.
  DateTime _cycleFilter = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final FinanceLocalRepository repo = VfinanceScope.of(context);
    if (_repositoryForStreams != repo) {
      _repositoryForStreams = repo;
      _creditCardsStream = repo.watchCreditCards();
      _invoicesStream = repo.watchInvoices();
    }
  }

  Future<void> _confirmDeleteCard(BuildContext context, CreditCard card) async {
    final AppLocalizations l = AppLocalizations.of(context)!;
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: Text(l.deleteConfirmTitle),
        content: Text(l.deleteConfirmCardBody),
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
      await repo.deleteCreditCard(card.id);
    } on CardDeleteBlockedException {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l.errorDeleteCardBlocked)));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l.errorWithMessage('$e'))));
      }
    }
  }

  /// Returns whether the row was deleted after confirmation.
  Future<bool> _confirmDeleteCardExpense(
    BuildContext context,
    FinanceTransaction row,
  ) async {
    final AppLocalizations l = AppLocalizations.of(context)!;
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: Text(l.deleteConfirmTitle),
        content: Text(l.deleteConfirmCardExpenseBody),
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
      return false;
    }
    final FinanceLocalRepository repo = VfinanceScope.of(context);
    try {
      await repo.deleteFinanceTransaction(row.id);
      return true;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l.errorWithMessage('$e'))));
      }
      return false;
    }
  }

  Future<void> _openCardExpensesDialog({
    required BuildContext hostContext,
    required CreditCard card,
    required List<Invoice> forCardAll,
    required List<Invoice> forCard,
    required FinanceLocalRepository repository,
  }) async {
    await showDialog<void>(
      context: hostContext,
      builder: (BuildContext dialogContext) {
        return _CardExpensesDialog(
          card: card,
          forCardAll: forCardAll,
          forCard: forCard,
          repository: repository,
          dateFormat: _dateFormat,
          belongs: _transactionBelongsToInvoice,
          confirmDeleteCardExpense: _confirmDeleteCardExpense,
        );
      },
    );
  }

  bool _transactionBelongsToInvoice({
    required FinanceTransaction transaction,
    required CreditCard card,
    required Invoice invoice,
  }) {
    if (transaction.cardId != card.id) {
      return false;
    }
    if (transaction.transactionType != TransactionType.expense.storageName) {
      return false;
    }
    if (transaction.paymentMethod != PaymentMethod.credit.storageName) {
      return false;
    }
    final DateTime civil = localCivilDateFromFinanceEpochMillis(
      transaction.dateUtcMillis,
    );
    final InvoiceCycleMonth cycle = computeInvoiceCycleMonth(
      purchaseDate: civil,
      closingDay: card.closingDay,
    );
    return cycle.year == invoice.year && cycle.month == invoice.month;
  }

  String _cycleFilterDisplayLabel(BuildContext context) {
    final Locale locale = Localizations.localeOf(context);
    return DateFormat.yMMMM(locale.toLanguageTag()).format(_cycleFilter);
  }

  void _shiftCycleFilterMonth(int monthDelta) {
    setState(() {
      _cycleFilter = DateTime(
        _cycleFilter.year,
        _cycleFilter.month + monthDelta,
      );
    });
  }

  List<int> _cycleYearPickerValues(int selectedYear) {
    final int nowYear = DateTime.now().year;
    const int spanPast = 12;
    const int spanFuture = 6;
    final List<int> years = <int>[
      for (int y = nowYear - spanPast; y <= nowYear + spanFuture; y++) y,
    ];
    if (!years.contains(selectedYear)) {
      years.add(selectedYear);
      years.sort();
    }
    return years;
  }

  Future<void> _showCycleMonthFilterDialog(BuildContext context) async {
    final AppLocalizations l = AppLocalizations.of(context)!;
    final Locale locale = Localizations.localeOf(context);
    final String monthNameLocale = locale.toLanguageTag();
    int selectedMonth = _cycleFilter.month;
    int selectedYear = _cycleFilter.year;
    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder:
              (
                BuildContext ctx,
                void Function(void Function()) setDialogState,
              ) {
                final List<int> yearItems = _cycleYearPickerValues(
                  selectedYear,
                );
                return AlertDialog(
                  title: Text(l.cardsFilterDialogTitle),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        DropdownButtonFormField<int>(
                          key: ValueKey<int>(selectedMonth),
                          initialValue: selectedMonth,
                          decoration: InputDecoration(
                            labelText: l.cardsMonthPickerLabel,
                          ),
                          items: List<DropdownMenuItem<int>>.generate(12, (
                            int index,
                          ) {
                            final int month = index + 1;
                            final String label = DateFormat.MMMM(
                              monthNameLocale,
                            ).format(DateTime(2000, month));
                            return DropdownMenuItem<int>(
                              value: month,
                              child: Text(label),
                            );
                          }),
                          onChanged: (int? value) {
                            if (value == null) {
                              return;
                            }
                            setDialogState(() => selectedMonth = value);
                          },
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<int>(
                          key: ValueKey<int>(selectedYear),
                          initialValue: selectedYear,
                          decoration: InputDecoration(
                            labelText: l.cardsYearField,
                          ),
                          items: yearItems.map((int y) {
                            return DropdownMenuItem<int>(
                              value: y,
                              child: Text('$y'),
                            );
                          }).toList(),
                          onChanged: (int? value) {
                            if (value == null) {
                              return;
                            }
                            setDialogState(() => selectedYear = value);
                          },
                        ),
                      ],
                    ),
                  ),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: Text(l.commonCancel),
                    ),
                    FilledButton(
                      onPressed: () {
                        setState(() {
                          _cycleFilter = DateTime(selectedYear, selectedMonth);
                        });
                        Navigator.pop(dialogContext);
                      },
                      child: Text(l.cardsFilterApply),
                    ),
                  ],
                );
              },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.cardsTitle),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.filter_alt_outlined),
            tooltip: l.cardsFilterTooltip,
            onPressed: () => _showCycleMonthFilterDialog(context),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(44),
          child: Padding(
            padding: const EdgeInsets.only(left: 12, right: 12, bottom: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: <Widget>[
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    tooltip: MaterialLocalizations.of(
                      context,
                    ).previousMonthTooltip,
                    onPressed: () => _shiftCycleFilterMonth(-1),
                  ),
                  Expanded(
                    child: Text(
                      _cycleFilterDisplayLabel(context),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    tooltip: MaterialLocalizations.of(context).nextMonthTooltip,
                    onPressed: () => _shiftCycleFilterMonth(1),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_cards',
        onPressed: () => context.push('/cards/add'),
        child: const Icon(Icons.add),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Expanded(
            child: StreamBuilder<List<CreditCard>>(
              stream: _creditCardsStream,
              builder: (BuildContext context, AsyncSnapshot<List<CreditCard>> sC) {
                if (sC.hasError) {
                  return Center(child: Text('${sC.error}'));
                }
                final List<CreditCard> cards = sC.data ?? <CreditCard>[];
                return StreamBuilder<List<Invoice>>(
                  stream: _invoicesStream,
                  builder:
                      (BuildContext context, AsyncSnapshot<List<Invoice>> sI) {
                        if (sI.hasError) {
                          return Center(child: Text('${sI.error}'));
                        }
                        final List<Invoice> invoices = sI.data ?? <Invoice>[];
                        if (cards.isEmpty) {
                          return Center(child: Text(l.cardsEmpty));
                        }
                        final Map<int, List<Invoice>> invoicesByCardId =
                            <int, List<Invoice>>{};
                        for (final Invoice inv in invoices) {
                          invoicesByCardId
                              .putIfAbsent(inv.cardId, () => <Invoice>[])
                              .add(inv);
                        }
                        for (final List<Invoice> list
                            in invoicesByCardId.values) {
                          list.sort((Invoice a, Invoice b) {
                            final int y = b.year.compareTo(a.year);
                            if (y != 0) {
                              return y;
                            }
                            return b.month.compareTo(a.month);
                          });
                        }
                        final FinanceLocalRepository repo = VfinanceScope.of(
                          context,
                        );
                        return ListView.builder(
                          itemCount: cards.length,
                          itemBuilder: (BuildContext context, int index) {
                            final CreditCard c = cards[index];
                            final List<Invoice> forCardAll =
                                invoicesByCardId[c.id] ?? const <Invoice>[];
                            final List<Invoice> forCard = forCardAll
                                .where(
                                  (Invoice inv) =>
                                      inv.year == _cycleFilter.year &&
                                      inv.month == _cycleFilter.month,
                                )
                                .toList();
                            return ListTile(
                              key: ValueKey<int>(c.id),
                              leading: const Icon(Icons.credit_card),
                              title: Text(c.name),
                              subtitle: Text(
                                '${l.cardsClosesOn(c.closingDay)} · '
                                '${l.cardsDueOn(c.dueDay)} · '
                                '${l.cardsLimit(formatCents(c.limitInCents))}',
                              ),
                              trailing: PopupMenuButton<String>(
                                onSelected: (String value) {
                                  if (value == 'edit') {
                                    context.push('/cards/edit/${c.id}');
                                  }
                                  if (value == 'delete') {
                                    _confirmDeleteCard(context, c);
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
                              onTap: () => _openCardExpensesDialog(
                                hostContext: context,
                                card: c,
                                forCardAll: forCardAll,
                                forCard: forCard,
                                repository: repo,
                              ),
                            );
                          },
                        );
                      },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  static Future<void> _openAdjustInvoice(
    BuildContext context, {
    required FinanceLocalRepository repository,
    required int cardId,
  }) async {
    final AppLocalizations l = AppLocalizations.of(context)!;
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    final TextEditingController adjusted = TextEditingController();
    final TextEditingController month = TextEditingController();
    final TextEditingController year = TextEditingController();
    final DateTime now = DateTime.now();
    month.text = now.month.toString();
    year.text = now.year.toString();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (BuildContext ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 8,
            bottom: MediaQuery.viewInsetsOf(ctx).bottom + 16,
          ),
          child: Form(
            key: formKey,
            child: ListView(
              shrinkWrap: true,
              children: <Widget>[
                Text(
                  l.cardsSheetAdjustInvoice,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  l.cardsAdjustInvoiceHint,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: month,
                  decoration: InputDecoration(labelText: l.cardsMonthField),
                  keyboardType: TextInputType.number,
                  validator: (String? v) {
                    final int? m = int.tryParse(v ?? '');
                    if (m == null || m < 1 || m > 12) {
                      return l.validationInvalidMonth;
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: year,
                  decoration: InputDecoration(labelText: l.cardsYearField),
                  keyboardType: TextInputType.number,
                  validator: (String? v) {
                    if (int.tryParse(v ?? '') == null) {
                      return l.validationInvalidYear;
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: adjusted,
                  decoration: InputDecoration(labelText: l.cardsAdjustedField),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (String? v) {
                    if (v == null || v.trim().isEmpty) {
                      return null;
                    }
                    try {
                      Money.parseReais(v);
                    } catch (_) {
                      return l.validationInvalidValue;
                    }
                    return null;
                  },
                ),
                FilledButton(
                  onPressed: () async {
                    if (!(formKey.currentState?.validate() ?? false)) {
                      return;
                    }
                    final int? adj = adjusted.text.trim().isEmpty
                        ? null
                        : Money.parseReais(adjusted.text).cents;
                    try {
                      await repository.upsertInvoiceAdjustment(
                        cardId: cardId,
                        month: int.parse(month.text.trim()),
                        year: int.parse(year.text.trim()),
                        adjustedTotalInCents: adj,
                      );
                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l.errorWithMessage('$e'))),
                        );
                      }
                    }
                  },
                  child: Text(l.cardsSaveAdjustment),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CardExpensesDialog extends StatefulWidget {
  const _CardExpensesDialog({
    required this.card,
    required this.forCardAll,
    required this.forCard,
    required this.repository,
    required this.dateFormat,
    required this.belongs,
    required this.confirmDeleteCardExpense,
  });

  final CreditCard card;
  final List<Invoice> forCardAll;
  final List<Invoice> forCard;
  final FinanceLocalRepository repository;
  final DateFormat dateFormat;
  final bool Function({
    required FinanceTransaction transaction,
    required CreditCard card,
    required Invoice invoice,
  })
  belongs;
  final Future<bool> Function(BuildContext context, FinanceTransaction row)
  confirmDeleteCardExpense;

  @override
  State<_CardExpensesDialog> createState() => _CardExpensesDialogState();
}

class _CardExpensesDialogState extends State<_CardExpensesDialog> {
  late Future<List<FinanceTransaction>> _transactionsFuture;

  @override
  void initState() {
    super.initState();
    _transactionsFuture = widget.repository.getCreditCardExpenseTransactions(
      widget.card.id,
    );
  }

  void _reloadTransactions() {
    setState(() {
      _transactionsFuture = widget.repository.getCreditCardExpenseTransactions(
        widget.card.id,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context)!;
    final double maxW = min(MediaQuery.sizeOf(context).width - 32, 560);
    final double maxH = min(MediaQuery.sizeOf(context).height * 0.85, 640);
    return Dialog(
      child: SizedBox(
        width: maxW,
        height: maxH,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 4, 0),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      widget.card.name,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: MaterialLocalizations.of(
                      context,
                    ).closeButtonTooltip,
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 4,
                children: <Widget>[
                  TextButton.icon(
                    onPressed: () async {
                      await context.push(
                        '/cards/${widget.card.id}/add-expense',
                      );
                      if (context.mounted) {
                        _reloadTransactions();
                      }
                    },
                    icon: const Icon(Icons.add_shopping_cart_outlined),
                    label: Text(l.cardsNewExpense),
                  ),
                  TextButton.icon(
                    onPressed: () async {
                      await _CardsScreenState._openAdjustInvoice(
                        context,
                        repository: widget.repository,
                        cardId: widget.card.id,
                      );
                      if (context.mounted) {
                        _reloadTransactions();
                      }
                    },
                    icon: const Icon(Icons.tune_outlined),
                    label: Text(l.cardsAdjustInvoice),
                  ),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<List<FinanceTransaction>>(
                future: _transactionsFuture,
                builder:
                    (
                      BuildContext context,
                      AsyncSnapshot<List<FinanceTransaction>> snapshot,
                    ) {
                      if (snapshot.hasError) {
                        return Center(child: Text('${snapshot.error}'));
                      }
                      if (snapshot.connectionState == ConnectionState.waiting &&
                          !snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final List<FinanceTransaction> allTx =
                          snapshot.data ?? <FinanceTransaction>[];
                      return ListView(
                        padding: const EdgeInsets.only(bottom: 12),
                        children: <Widget>[
                          if (widget.forCardAll.isEmpty)
                            ListTile(title: Text(l.cardsNoInvoices))
                          else if (widget.forCard.isEmpty)
                            ListTile(
                              title: Text(l.cardsNoInvoiceInSelectedMonth),
                            )
                          else
                            ...widget.forCard.map(
                              (Invoice i) => _InvoiceCycleTile(
                                card: widget.card,
                                invoice: i,
                                allTransactions: allTx,
                                dateFormat: widget.dateFormat,
                                belongs: widget.belongs,
                                onEdit: (FinanceTransaction t) {
                                  context
                                      .push<void>('/cards/expense/edit/${t.id}')
                                      .then((void _) {
                                        if (mounted) {
                                          _reloadTransactions();
                                        }
                                      });
                                },
                                onDelete: (FinanceTransaction t) {
                                  widget
                                      .confirmDeleteCardExpense(context, t)
                                      .then((bool deleted) {
                                        if (deleted && mounted) {
                                          _reloadTransactions();
                                        }
                                      });
                                },
                              ),
                            ),
                        ],
                      );
                    },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InvoiceCycleTile extends StatelessWidget {
  const _InvoiceCycleTile({
    required this.card,
    required this.invoice,
    required this.allTransactions,
    required this.dateFormat,
    required this.belongs,
    required this.onEdit,
    required this.onDelete,
  });

  final CreditCard card;
  final Invoice invoice;
  final List<FinanceTransaction> allTransactions;
  final DateFormat dateFormat;
  final bool Function({
    required FinanceTransaction transaction,
    required CreditCard card,
    required Invoice invoice,
  })
  belongs;
  final void Function(FinanceTransaction transaction) onEdit;
  final void Function(FinanceTransaction transaction) onDelete;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context)!;
    final (DateTime start, DateTime end) = invoiceCyclePurchaseInclusiveBounds(
      cycleYear: invoice.year,
      cycleMonth: invoice.month,
      closingDay: card.closingDay,
    );
    final DateTime due = invoiceDueDateForCycle(
      cycleYear: invoice.year,
      cycleMonth: invoice.month,
      dueDay: card.dueDay,
    );
    final List<FinanceTransaction> expenses =
        allTransactions
            .where(
              (FinanceTransaction t) =>
                  belongs(transaction: t, card: card, invoice: invoice),
            )
            .toList()
          ..sort(
            (FinanceTransaction a, FinanceTransaction b) =>
                b.dateUtcMillis.compareTo(a.dateUtcMillis),
          );
    final ThemeData theme = Theme.of(context);
    final String totalLine = invoice.adjustedTotalInCents != null
        ? l.cardsTotalAdjusted(
            formatCents(invoice.totalInCents),
            formatCents(invoice.adjustedTotalInCents!),
          )
        : l.cardsTotalOnly(formatCents(invoice.totalInCents));
    final String statusLine = invoiceShowsAsOpenInList(isPaid: invoice.isPaid)
        ? l.cardsStatusOpen
        : l.cardsStatusPaid;
    return Card(
      margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        l.cardsInvoiceCycleSummary(
                          dateFormat.format(start),
                          dateFormat.format(end),
                          dateFormat.format(due),
                        ),
                        style: theme.textTheme.titleSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(totalLine, style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(statusLine, style: theme.textTheme.labelMedium),
              ],
            ),
          ),
          const Divider(height: 1),
          if (expenses.isEmpty)
            ListTile(dense: true, title: Text(l.cardsNoExpensesInCycle))
          else
            ...expenses.map(
              (FinanceTransaction t) => ListTile(
                dense: true,
                title: Text(t.description),
                subtitle: Text(
                  '${dateFormat.format(localCivilDateFromFinanceEpochMillis(t.dateUtcMillis))} · '
                  '${t.category}',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      formatCents(t.amountInCents),
                      style: theme.textTheme.titleSmall,
                    ),
                    PopupMenuButton<String>(
                      onSelected: (String value) {
                        if (value == 'edit') {
                          onEdit(t);
                        }
                        if (value == 'delete') {
                          onDelete(t);
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
                onTap: () => onEdit(t),
              ),
            ),
        ],
      ),
    );
  }
}

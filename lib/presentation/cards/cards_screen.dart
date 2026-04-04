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
  late Stream<List<FinanceTransaction>> _transactionsStream;
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final FinanceLocalRepository repo = VfinanceScope.of(context);
    if (_repositoryForStreams != repo) {
      _repositoryForStreams = repo;
      _creditCardsStream = repo.watchCreditCards();
      _invoicesStream = repo.watchInvoices();
      _transactionsStream = repo.watchFinanceTransactions();
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

  Future<void> _confirmDeleteCardExpense(
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

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l.cardsTitle)),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_cards',
        onPressed: () => context.push('/cards/add'),
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<CreditCard>>(
        stream: _creditCardsStream,
        builder: (BuildContext context, AsyncSnapshot<List<CreditCard>> sC) {
          if (sC.hasError) {
            return Center(child: Text('${sC.error}'));
          }
          final List<CreditCard> cards = sC.data ?? <CreditCard>[];
          return StreamBuilder<List<Invoice>>(
            stream: _invoicesStream,
            builder: (BuildContext context, AsyncSnapshot<List<Invoice>> sI) {
              if (sI.hasError) {
                return Center(child: Text('${sI.error}'));
              }
              final List<Invoice> invoices = sI.data ?? <Invoice>[];
              return StreamBuilder<List<FinanceTransaction>>(
                stream: _transactionsStream,
                builder:
                    (
                      BuildContext context,
                      AsyncSnapshot<List<FinanceTransaction>> sT,
                    ) {
                      if (sT.hasError) {
                        return Center(child: Text('${sT.error}'));
                      }
                      final List<FinanceTransaction> allTx =
                          sT.data ?? <FinanceTransaction>[];
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
                      return ListView.builder(
                        itemCount: cards.length,
                        itemBuilder: (BuildContext context, int index) {
                          final CreditCard c = cards[index];
                          final List<Invoice> forCard =
                              invoicesByCardId[c.id] ?? const <Invoice>[];
                          return ExpansionTile(
                            key: ValueKey<int>(c.id),
                            leading: const Icon(Icons.credit_card),
                            title: Row(
                              children: <Widget>[
                                Expanded(child: Text(c.name)),
                                PopupMenuButton<String>(
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
                              ],
                            ),
                            subtitle: Text(
                              '${l.cardsClosesOn(c.closingDay)} · '
                              '${l.cardsDueOn(c.dueDay)} · '
                              '${l.cardsLimit(formatCents(c.limitInCents))}',
                            ),
                            children: <Widget>[
                              Wrap(
                                alignment: WrapAlignment.end,
                                spacing: 8,
                                runSpacing: 4,
                                children: <Widget>[
                                  TextButton.icon(
                                    onPressed: () => context.push(
                                      '/cards/${c.id}/add-expense',
                                    ),
                                    icon: const Icon(
                                      Icons.add_shopping_cart_outlined,
                                    ),
                                    label: Text(l.cardsNewExpense),
                                  ),
                                  TextButton.icon(
                                    onPressed: () => _openAdjustInvoice(
                                      context,
                                      repository: VfinanceScope.of(context),
                                      cardId: c.id,
                                    ),
                                    icon: const Icon(Icons.tune_outlined),
                                    label: Text(l.cardsAdjustInvoice),
                                  ),
                                ],
                              ),
                              if (forCard.isEmpty)
                                ListTile(title: Text(l.cardsNoInvoices))
                              else
                                ...forCard.map(
                                  (Invoice i) => _InvoiceCycleTile(
                                    card: c,
                                    invoice: i,
                                    allTransactions: allTx,
                                    dateFormat: _dateFormat,
                                    belongs: _transactionBelongsToInvoice,
                                    onEdit: (FinanceTransaction t) {
                                      context.push(
                                        '/cards/expense/edit/${t.id}',
                                      );
                                    },
                                    onDelete: (FinanceTransaction t) {
                                      _confirmDeleteCardExpense(context, t);
                                    },
                                  ),
                                ),
                            ],
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
    return ExpansionTile(
      title: Text(
        l.cardsInvoiceCycleSummary(
          dateFormat.format(start),
          dateFormat.format(end),
          dateFormat.format(due),
        ),
      ),
      subtitle: Text(
        invoice.adjustedTotalInCents != null
            ? l.cardsTotalAdjusted(
                formatCents(invoice.totalInCents),
                formatCents(invoice.adjustedTotalInCents!),
              )
            : l.cardsTotalOnly(formatCents(invoice.totalInCents)),
      ),
      trailing: Text(
        invoiceShowsAsOpenInList(isPaid: invoice.isPaid)
            ? l.cardsStatusOpen
            : l.cardsStatusPaid,
      ),
      children: <Widget>[
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
                    style: Theme.of(context).textTheme.titleSmall,
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
                    itemBuilder: (BuildContext ctx) => <PopupMenuEntry<String>>[
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
    );
  }
}

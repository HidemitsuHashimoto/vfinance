import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vfinance/app/vfinance_scope.dart';
import 'package:vfinance/data/local/app_database.dart';
import 'package:vfinance/data/local/finance_local_repository.dart';
import 'package:vfinance/domain/invoice_rules.dart';
import 'package:vfinance/domain/money.dart';
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
              return ListView.builder(
                itemCount: cards.length,
                itemBuilder: (BuildContext context, int index) {
                  final CreditCard c = cards[index];
                  final List<Invoice> forCard =
                      invoicesByCardId[c.id] ?? const <Invoice>[];
                  return ExpansionTile(
                    key: ValueKey<int>(c.id),
                    leading: const Icon(Icons.credit_card),
                    title: Text(c.name),
                    subtitle: Text(
                      '${l.cardsClosesOn(c.closingDay)} · '
                      '${l.cardsDueOn(c.dueDay)} · '
                      '${l.cardsLimit(formatCents(c.limitInCents))}',
                    ),
                    children: <Widget>[
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () => _openAddInvoice(
                            context,
                            repository: VfinanceScope.of(context),
                            cardId: c.id,
                          ),
                          icon: const Icon(Icons.note_add_outlined),
                          label: Text(l.cardsNewInvoice),
                        ),
                      ),
                      if (forCard.isEmpty)
                        ListTile(title: Text(l.cardsNoInvoices))
                      else
                        ...forCard.map(
                          (Invoice i) => ListTile(
                            title: Text(
                              l.cardsInvoiceLine(
                                i.month.toString().padLeft(2, '0'),
                                '${i.year}',
                              ),
                            ),
                            subtitle: Text(
                              i.adjustedTotalInCents != null
                                  ? l.cardsTotalAdjusted(
                                      formatCents(i.totalInCents),
                                      formatCents(i.adjustedTotalInCents!),
                                    )
                                  : l.cardsTotalOnly(
                                      formatCents(i.totalInCents),
                                    ),
                            ),
                            trailing: Text(
                              invoiceShowsAsOpenInList(isPaid: i.isPaid)
                                  ? l.cardsStatusOpen
                                  : l.cardsStatusPaid,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  static Future<void> _openAddInvoice(
    BuildContext context, {
    required FinanceLocalRepository repository,
    required int cardId,
  }) async {
    final AppLocalizations l = AppLocalizations.of(context)!;
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    final TextEditingController total = TextEditingController();
    final TextEditingController adjusted = TextEditingController();
    final TextEditingController month = TextEditingController();
    final TextEditingController year = TextEditingController();
    final DateTime now = DateTime.now();
    month.text = now.month.toString();
    year.text = now.year.toString();
    bool isClosed = false;
    bool isPaid = false;
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
          child: StatefulBuilder(
            builder:
                (BuildContext context, void Function(void Function()) setM) {
                  return Form(
                    key: formKey,
                    child: ListView(
                      shrinkWrap: true,
                      children: <Widget>[
                        Text(
                          l.cardsSheetNewInvoice,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: month,
                          decoration: InputDecoration(
                            labelText: l.cardsMonthField,
                          ),
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
                          decoration: InputDecoration(
                            labelText: l.cardsYearField,
                          ),
                          keyboardType: TextInputType.number,
                          validator: (String? v) {
                            if (int.tryParse(v ?? '') == null) {
                              return l.validationInvalidYear;
                            }
                            return null;
                          },
                        ),
                        TextFormField(
                          controller: total,
                          decoration: InputDecoration(
                            labelText: l.cardsTotalField,
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          validator: (String? v) {
                            if (v == null || v.trim().isEmpty) {
                              return l.validationTotalRequired;
                            }
                            try {
                              Money.parseReais(v);
                            } catch (_) {
                              return l.validationInvalidValue;
                            }
                            return null;
                          },
                        ),
                        TextFormField(
                          controller: adjusted,
                          decoration: InputDecoration(
                            labelText: l.cardsAdjustedField,
                          ),
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
                        SwitchListTile(
                          title: Text(l.cardsClosedSwitch),
                          value: isClosed,
                          onChanged: (bool v) => setM(() => isClosed = v),
                        ),
                        SwitchListTile(
                          title: Text(l.cardsPaidSwitch),
                          value: isPaid,
                          onChanged: (bool v) => setM(() => isPaid = v),
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
                              await repository.insertInvoice(
                                cardId: cardId,
                                month: int.parse(month.text.trim()),
                                year: int.parse(year.text.trim()),
                                totalInCents: Money.parseReais(
                                  total.text.trim(),
                                ).cents,
                                adjustedTotalInCents: adj,
                                isClosed: isClosed,
                                isPaid: isPaid,
                              );
                              if (context.mounted) {
                                Navigator.pop(context);
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(l.errorWithMessage('$e')),
                                  ),
                                );
                              }
                            }
                          },
                          child: Text(l.cardsSaveInvoice),
                        ),
                      ],
                    ),
                  );
                },
          ),
        );
      },
    );
  }
}

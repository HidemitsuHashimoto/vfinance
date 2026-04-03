import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vfinance/app/vfinance_scope.dart';
import 'package:vfinance/data/local/app_database.dart';
import 'package:vfinance/data/local/finance_local_repository.dart';
import 'package:vfinance/domain/invoice_rules.dart';
import 'package:vfinance/domain/money.dart';
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
    return Scaffold(
      appBar: AppBar(title: const Text('Cartões')),
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
                return const Center(
                  child: Text('Nenhum cartão. Toque em + para criar.'),
                );
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
                      'Fecha dia ${c.closingDay} · '
                      'Vence dia ${c.dueDay} · '
                      'Limite ${formatCents(c.limitInCents)}',
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
                          label: const Text('Nova fatura'),
                        ),
                      ),
                      if (forCard.isEmpty)
                        const ListTile(title: Text('Sem faturas registradas'))
                      else
                        ...forCard.map(
                          (Invoice i) => ListTile(
                            title: Text(
                              'Fatura ${i.month.toString().padLeft(2, '0')}/'
                              '${i.year}',
                            ),
                            subtitle: Text(
                              i.adjustedTotalInCents != null
                                  ? 'Total ${formatCents(i.totalInCents)} · '
                                        'Ajustado '
                                        '${formatCents(i.adjustedTotalInCents!)}'
                                  : 'Total ${formatCents(i.totalInCents)}',
                            ),
                            trailing: Text(
                              invoiceAffectsTotalUserBalance(isPaid: i.isPaid)
                                  ? 'Em aberto'
                                  : 'Paga',
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
                          'Nova fatura',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: month,
                          decoration: const InputDecoration(
                            labelText: 'Mês (1–12)',
                          ),
                          keyboardType: TextInputType.number,
                          validator: (String? v) {
                            final int? m = int.tryParse(v ?? '');
                            if (m == null || m < 1 || m > 12) {
                              return 'Mês inválido';
                            }
                            return null;
                          },
                        ),
                        TextFormField(
                          controller: year,
                          decoration: const InputDecoration(labelText: 'Ano'),
                          keyboardType: TextInputType.number,
                          validator: (String? v) {
                            if (int.tryParse(v ?? '') == null) {
                              return 'Ano inválido';
                            }
                            return null;
                          },
                        ),
                        TextFormField(
                          controller: total,
                          decoration: const InputDecoration(
                            labelText: 'Total (R\$)',
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          validator: (String? v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Informe o total';
                            }
                            try {
                              Money.parseReais(v);
                            } catch (_) {
                              return 'Valor inválido';
                            }
                            return null;
                          },
                        ),
                        TextFormField(
                          controller: adjusted,
                          decoration: const InputDecoration(
                            labelText: 'Total ajustado (opcional, R\$)',
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
                              return 'Valor inválido';
                            }
                            return null;
                          },
                        ),
                        SwitchListTile(
                          title: const Text('Fatura fechada'),
                          value: isClosed,
                          onChanged: (bool v) => setM(() => isClosed = v),
                        ),
                        SwitchListTile(
                          title: const Text('Fatura paga'),
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
                                  SnackBar(content: Text('Erro: $e')),
                                );
                              }
                            }
                          },
                          child: const Text('Salvar fatura'),
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

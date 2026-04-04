import 'package:flutter/material.dart';
import 'package:vfinance/app/pop_current_route.dart';
import 'package:vfinance/app/vfinance_scope.dart';
import 'package:vfinance/data/local/app_database.dart';
import 'package:vfinance/data/local/finance_local_repository.dart';
import 'package:vfinance/domain/money.dart';
import 'package:vfinance/domain/transaction_enums.dart';
import 'package:vfinance/l10n/app_localizations.dart';
import 'package:vfinance/presentation/l10n/transaction_labels.dart';

/// Registers income/expense with payment method and optional links.
class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _amount = TextEditingController();
  final TextEditingController _category = TextEditingController();
  final TextEditingController _description = TextEditingController();
  TransactionType _type = TransactionType.expense;
  PaymentMethod _method = PaymentMethod.debit;
  DateTime _dateUtc = DateTime.utc(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );
  int? _accountId;
  int? _cardId;
  FinanceLocalRepository? _repositoryForStreams;
  Stream<List<Account>>? _accountsStream;
  Stream<List<CreditCard>>? _cardsStream;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final FinanceLocalRepository repo = VfinanceScope.of(context);
    if (_repositoryForStreams != repo) {
      _repositoryForStreams = repo;
      _accountsStream = repo.watchAccounts();
      _cardsStream = repo.watchCreditCards();
    }
  }

  @override
  void dispose() {
    _amount.dispose();
    _category.dispose();
    _description.dispose();
    super.dispose();
  }

  bool _needsAccount() => _method != PaymentMethod.credit;

  bool _needsCard() => _method == PaymentMethod.credit;

  Future<void> _pickDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(_dateUtc.year, _dateUtc.month, _dateUtc.day),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      locale: const Locale('pt', 'BR'),
    );
    if (picked != null) {
      setState(() {
        _dateUtc = DateTime.utc(picked.year, picked.month, picked.day);
      });
    }
  }

  Future<void> _submit(BuildContext context) async {
    final AppLocalizations l = AppLocalizations.of(context)!;
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final FinanceLocalRepository repo = VfinanceScope.of(context);
    int? accountId = _accountId;
    int? cardId = _cardId;
    if (_needsAccount()) {
      if (accountId == null) {
        final List<Account> list = await repo.watchAccounts().first;
        if (!context.mounted) {
          return;
        }
        if (list.isEmpty) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l.registerAccountFirst)));
          return;
        }
        accountId = list.first.id;
      }
    }
    if (_needsCard()) {
      if (cardId == null) {
        final List<CreditCard> list = await repo.watchCreditCards().first;
        if (!context.mounted) {
          return;
        }
        if (list.isEmpty) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l.registerCardFirst)));
          return;
        }
        cardId = list.first.id;
      }
    }
    final int cents = Money.parseReais(_amount.text).cents;
    try {
      await repo.insertFinanceTransaction(
        amountInCents: cents,
        transactionType: _type,
        category: _category.text.trim(),
        description: _description.text.trim(),
        dateUtc: _dateUtc,
        paymentMethod: _method,
        accountId: _needsAccount() ? accountId : null,
        cardId: _needsCard() ? cardId : null,
      );
      if (context.mounted) {
        popCurrentRoute(context);
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
    final Stream<List<Account>> accountsStream = _accountsStream!;
    final Stream<List<CreditCard>> cardsStream = _cardsStream!;
    return Scaffold(
      appBar: AppBar(title: Text(l.addTransactionTitle)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            SegmentedButton<TransactionType>(
              segments: <ButtonSegment<TransactionType>>[
                ButtonSegment<TransactionType>(
                  value: TransactionType.expense,
                  label: Text(l.addTransactionExpense),
                ),
                ButtonSegment<TransactionType>(
                  value: TransactionType.income,
                  label: Text(l.addTransactionIncome),
                ),
              ],
              selected: <TransactionType>{_type},
              onSelectionChanged: (Set<TransactionType> s) {
                setState(() => _type = s.first);
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<PaymentMethod>(
              initialValue: _method,
              decoration: InputDecoration(
                labelText: l.addTransactionPaymentMethod,
              ),
              items: PaymentMethod.values
                  .map(
                    (PaymentMethod m) => DropdownMenuItem<PaymentMethod>(
                      value: m,
                      child: Text(labelPaymentMethod(l, m)),
                    ),
                  )
                  .toList(),
              onChanged: (PaymentMethod? m) {
                if (m != null) {
                  setState(() => _method = m);
                }
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amount,
              decoration: InputDecoration(
                labelText: l.addTransactionAmountLabel,
                hintText: '0,00',
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (String? v) {
                if (v == null || v.trim().isEmpty) {
                  return l.validationValueRequired;
                }
                try {
                  Money.parseReais(v);
                } catch (_) {
                  return l.validationInvalidValue;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _category,
              decoration: InputDecoration(
                labelText: l.addTransactionCategoryLabel,
              ),
              validator: (String? v) {
                if (v == null || v.trim().isEmpty) {
                  return l.validationCategoryRequired;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _description,
              decoration: InputDecoration(
                labelText: l.addTransactionDescriptionLabel,
              ),
              validator: (String? v) {
                if (v == null || v.trim().isEmpty) {
                  return l.validationDescriptionRequired;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            ListTile(
              title: Text(l.addTransactionDateLabel),
              subtitle: Text(
                '${_dateUtc.day.toString().padLeft(2, '0')}/'
                '${_dateUtc.month.toString().padLeft(2, '0')}/'
                '${_dateUtc.year}',
              ),
              trailing: IconButton(
                icon: const Icon(Icons.calendar_month),
                onPressed: () => _pickDate(context),
              ),
            ),
            if (_needsAccount()) ...<Widget>[
              const SizedBox(height: 8),
              StreamBuilder<List<Account>>(
                stream: accountsStream,
                builder:
                    (BuildContext context, AsyncSnapshot<List<Account>> s) {
                      final List<Account> accounts = s.data ?? <Account>[];
                      if (accounts.isEmpty) {
                        return Text(l.registerAccountFirst);
                      }
                      return DropdownButtonFormField<int>(
                        initialValue: _accountId ?? accounts.first.id,
                        decoration: InputDecoration(
                          labelText: l.addTransactionAccountLabel,
                        ),
                        items: accounts
                            .map(
                              (Account a) => DropdownMenuItem<int>(
                                value: a.id,
                                child: Text(a.name),
                              ),
                            )
                            .toList(),
                        onChanged: (int? id) => setState(() => _accountId = id),
                      );
                    },
              ),
            ],
            if (_needsCard()) ...<Widget>[
              const SizedBox(height: 8),
              StreamBuilder<List<CreditCard>>(
                stream: cardsStream,
                builder:
                    (BuildContext context, AsyncSnapshot<List<CreditCard>> s) {
                      final List<CreditCard> cards = s.data ?? <CreditCard>[];
                      if (cards.isEmpty) {
                        return Text(l.registerCardFirst);
                      }
                      return DropdownButtonFormField<int>(
                        initialValue: _cardId ?? cards.first.id,
                        decoration: InputDecoration(
                          labelText: l.addTransactionCardLabel,
                        ),
                        items: cards
                            .map(
                              (CreditCard c) => DropdownMenuItem<int>(
                                value: c.id,
                                child: Text(c.name),
                              ),
                            )
                            .toList(),
                        onChanged: (int? id) => setState(() => _cardId = id),
                      );
                    },
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => _submit(context),
              child: Text(l.commonSave),
            ),
          ],
        ),
      ),
    );
  }
}

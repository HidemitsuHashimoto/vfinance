import 'package:flutter/material.dart';
import 'package:vfinance/app/pop_current_route.dart';
import 'package:vfinance/app/vfinance_scope.dart';
import 'package:vfinance/data/local/app_database.dart';
import 'package:vfinance/data/local/finance_local_repository.dart';
import 'package:vfinance/domain/finance_calendar_date.dart';
import 'package:vfinance/domain/money.dart';
import 'package:vfinance/domain/transaction_enums.dart';
import 'package:vfinance/l10n/app_localizations.dart';
import 'package:vfinance/presentation/formatting/amount_format.dart';
import 'package:vfinance/presentation/l10n/transaction_labels.dart';

/// Registers or edits income/expense with payment method and optional links.
///
/// When [forceCardCreditFlow] is true, the form is fixed to expense on credit.
/// For novo gasto, pass [initialCardId]. For editing, [transactionId] supplies
/// the card after load.
class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({
    super.key,
    this.transactionId,
    this.initialCardId,
    this.forceCardCreditFlow = false,
  });

  /// When set, loads the row and updates on save.
  final int? transactionId;

  /// Pre-selected card when opened from the Cartões flow.
  final int? initialCardId;

  /// If true, payment method is always credit and [initialCardId] is used.
  final bool forceCardCreditFlow;

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  static const int _maxInstallments = 60;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _amount = TextEditingController();
  final TextEditingController _installments = TextEditingController(text: '1');
  final TextEditingController _category = TextEditingController();
  final TextEditingController _description = TextEditingController();
  TransactionType _type = TransactionType.expense;
  PaymentMethod _method = PaymentMethod.debit;
  late int _dateEpochMillis;
  int? _accountId;
  int? _cardId;
  FinanceLocalRepository? _repositoryForStreams;
  Stream<List<Account>>? _accountsStream;
  Stream<List<CreditCard>>? _cardsStream;
  bool _isLoadingEdit = false;
  bool _didStartLoad = false;

  @override
  void initState() {
    super.initState();
    _isLoadingEdit = widget.transactionId != null;
    final DateTime now = DateTime.now();
    _dateEpochMillis = financeEpochMillisFromLocalYmd(
      now.year,
      now.month,
      now.day,
    );
    if (widget.forceCardCreditFlow && widget.initialCardId != null) {
      _method = PaymentMethod.credit;
      _cardId = widget.initialCardId;
      _type = TransactionType.expense;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final FinanceLocalRepository repo = VfinanceScope.of(context);
    if (_repositoryForStreams != repo) {
      _repositoryForStreams = repo;
      _accountsStream = repo.watchAccounts();
      _cardsStream = repo.watchCreditCards();
    }
    if (widget.transactionId != null && !_didStartLoad) {
      _didStartLoad = true;
      repo.getFinanceTransactionById(widget.transactionId!).then((
        FinanceTransaction? t,
      ) {
        if (!mounted) {
          return;
        }
        if (t == null) {
          popCurrentRoute(context);
          return;
        }
        final bool isCardExpense =
            t.transactionType == TransactionType.expense.storageName &&
            t.paymentMethod == PaymentMethod.credit.storageName &&
            t.cardId != null;
        if (isCardExpense && !widget.forceCardCreditFlow) {
          popCurrentRoute(context);
          return;
        }
        setState(() {
          _isLoadingEdit = false;
          _type = TransactionType.parseStorage(t.transactionType);
          _method = PaymentMethod.parseStorage(t.paymentMethod);
          _amount.text = formatCentsAsReaisInput(t.amountInCents);
          _category.text = t.category;
          _description.text = t.description;
          _dateEpochMillis = t.dateUtcMillis;
          _accountId = t.accountId;
          _cardId = t.cardId;
        });
      });
    }
  }

  @override
  void dispose() {
    _amount.dispose();
    _installments.dispose();
    _category.dispose();
    _description.dispose();
    super.dispose();
  }

  bool _needsAccount() => _method != PaymentMethod.credit;

  bool _needsCard() => _method == PaymentMethod.credit;

  bool _hideCreditForNewGlobalTransaction() {
    return widget.transactionId == null && !widget.forceCardCreditFlow;
  }

  /// Parses [_installments] when the card-expense flow shows the field;
  /// otherwise returns [1].
  int _parseInstallmentCount() {
    if (!(widget.forceCardCreditFlow && widget.transactionId == null)) {
      return 1;
    }
    final String raw = _installments.text.trim();
    if (raw.isEmpty) {
      return 1;
    }
    final int? parsed = int.tryParse(raw);
    if (parsed == null) {
      return 0;
    }
    return parsed;
  }

  int? _accountDropdownValue(List<Account> accounts) {
    if (accounts.isEmpty) {
      return null;
    }
    if (_accountId != null) {
      for (final Account a in accounts) {
        if (a.id == _accountId) {
          return _accountId;
        }
      }
    }
    return accounts.first.id;
  }

  int? _cardDropdownValue(List<CreditCard> cards) {
    if (cards.isEmpty) {
      return null;
    }
    if (_cardId != null) {
      for (final CreditCard c in cards) {
        if (c.id == _cardId) {
          return _cardId;
        }
      }
    }
    return cards.first.id;
  }

  Future<void> _pickDate(BuildContext context) async {
    final DateTime civil = localCivilDateFromFinanceEpochMillis(
      _dateEpochMillis,
    );
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(civil.year, civil.month, civil.day),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      locale: const Locale('pt', 'BR'),
    );
    if (picked != null) {
      setState(() {
        _dateEpochMillis = financeEpochMillisFromLocalYmd(
          picked.year,
          picked.month,
          picked.day,
        );
      });
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
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
      await repo.deleteFinanceTransaction(widget.transactionId!);
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
    } else {
      accountId = null;
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
    } else {
      cardId = null;
    }
    final int cents = Money.parseReais(_amount.text).cents;
    final DateTime dateForRepo = DateTime.fromMillisecondsSinceEpoch(
      _dateEpochMillis,
    );
    final int installmentCount = _parseInstallmentCount();
    try {
      if (widget.transactionId == null) {
        final bool isNewCardInstallmentFlow =
            widget.forceCardCreditFlow &&
            _method == PaymentMethod.credit &&
            installmentCount > 1;
        if (isNewCardInstallmentFlow) {
          final List<String> rowDescriptions = List<String>.generate(
            installmentCount,
            (int i) => l.addCardExpenseInstallmentLineDescription(
              _description.text.trim(),
              i + 1,
              installmentCount,
            ),
          );
          await repo.insertCreditCardInstallmentExpensePlan(
            totalAmountInCents: cents,
            installmentCount: installmentCount,
            category: _category.text.trim(),
            rowDescriptions: rowDescriptions,
            firstPurchaseDate: dateForRepo,
            cardId: cardId!,
          );
        } else {
          await repo.insertFinanceTransaction(
            amountInCents: cents,
            transactionType: _type,
            category: _category.text.trim(),
            description: _description.text.trim(),
            dateUtc: dateForRepo,
            paymentMethod: _method,
            accountId: _needsAccount() ? accountId : null,
            cardId: _needsCard() ? cardId : null,
          );
        }
      } else {
        await repo.updateFinanceTransaction(
          id: widget.transactionId!,
          amountInCents: cents,
          transactionType: _type,
          category: _category.text.trim(),
          description: _description.text.trim(),
          dateUtc: dateForRepo,
          paymentMethod: _method,
          accountId: _needsAccount() ? accountId : null,
          cardId: _needsCard() ? cardId : null,
        );
      }
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
    final bool isEdit = widget.transactionId != null;
    final DateTime civil = localCivilDateFromFinanceEpochMillis(
      _dateEpochMillis,
    );
    final List<PaymentMethod> methodChoices =
        _hideCreditForNewGlobalTransaction()
        ? PaymentMethod.values
              .where((PaymentMethod m) => m != PaymentMethod.credit)
              .toList()
        : PaymentMethod.values.toList();
    final String title = widget.forceCardCreditFlow
        ? (isEdit ? l.editCardExpenseTitle : l.addCardExpenseTitle)
        : (isEdit ? l.editTransactionTitle : l.addTransactionTitle);
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: _isLoadingEdit
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: <Widget>[
                  if (widget.forceCardCreditFlow)
                    InputDecorator(
                      decoration: InputDecoration(
                        labelText: l.addTransactionExpense,
                      ),
                      child: Text(l.transactionKindExpense),
                    )
                  else
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
                  if (widget.forceCardCreditFlow)
                    StreamBuilder<List<CreditCard>>(
                      stream: cardsStream,
                      builder:
                          (
                            BuildContext context,
                            AsyncSnapshot<List<CreditCard>> s,
                          ) {
                            final List<CreditCard> cards =
                                s.data ?? <CreditCard>[];
                            final int? cardKey = _cardId ?? widget.initialCardId;
                            CreditCard? card;
                            if (cardKey != null) {
                              for (final CreditCard c in cards) {
                                if (c.id == cardKey) {
                                  card = c;
                                  break;
                                }
                              }
                            }
                            return InputDecorator(
                              decoration: InputDecoration(
                                labelText: l.addTransactionPaymentMethod,
                              ),
                              child: Text(
                                '${labelPaymentMethod(l, PaymentMethod.credit)} · '
                                '${card?.name ?? '…'}',
                              ),
                            );
                          },
                    )
                  else
                    DropdownButtonFormField<PaymentMethod>(
                      key: ValueKey<PaymentMethod>(_method),
                      initialValue: methodChoices.contains(_method)
                          ? _method
                          : methodChoices.first,
                      decoration: InputDecoration(
                        labelText: l.addTransactionPaymentMethod,
                      ),
                      items: methodChoices
                          .map(
                            (PaymentMethod m) =>
                                DropdownMenuItem<PaymentMethod>(
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
                  if (widget.forceCardCreditFlow && !isEdit) ...<Widget>[
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _installments,
                      decoration: InputDecoration(
                        labelText: l.addCardExpenseInstallmentsLabel,
                        hintText: '1',
                        helperText: l.addCardExpenseInstallmentsHint,
                      ),
                      keyboardType: TextInputType.number,
                      validator: (String? v) {
                        final int n = _parseInstallmentCount();
                        if (n < 1 || n > _maxInstallments) {
                          return l.validationInstallmentsRange;
                        }
                        return null;
                      },
                    ),
                  ],
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
                      '${civil.day.toString().padLeft(2, '0')}/'
                      '${civil.month.toString().padLeft(2, '0')}/'
                      '${civil.year}',
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
                          (
                            BuildContext context,
                            AsyncSnapshot<List<Account>> s,
                          ) {
                            final List<Account> accounts =
                                s.data ?? <Account>[];
                            if (accounts.isEmpty) {
                              return Text(l.registerAccountFirst);
                            }
                            final int? v = _accountDropdownValue(accounts);
                            return DropdownButtonFormField<int>(
                              key: ValueKey<int?>(v),
                              initialValue: v,
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
                              onChanged: (int? id) =>
                                  setState(() => _accountId = id),
                            );
                          },
                    ),
                  ],
                  if (_needsCard() && !widget.forceCardCreditFlow) ...<Widget>[
                    const SizedBox(height: 8),
                    StreamBuilder<List<CreditCard>>(
                      stream: cardsStream,
                      builder:
                          (
                            BuildContext context,
                            AsyncSnapshot<List<CreditCard>> s,
                          ) {
                            final List<CreditCard> cards =
                                s.data ?? <CreditCard>[];
                            if (cards.isEmpty) {
                              return Text(l.registerCardFirst);
                            }
                            final int? v = _cardDropdownValue(cards);
                            return DropdownButtonFormField<int>(
                              key: ValueKey<int?>(v),
                              initialValue: v,
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
                              onChanged: (int? id) =>
                                  setState(() => _cardId = id),
                            );
                          },
                    ),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () => _submit(context),
                    child: Text(l.commonSave),
                  ),
                  if (isEdit) ...<Widget>[
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => _confirmDelete(context),
                      child: Text(
                        l.menuDelete,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}

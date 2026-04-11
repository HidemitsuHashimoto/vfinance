import 'package:drift/drift.dart';
import 'package:vfinance/data/local/app_database.dart';
import 'package:vfinance/domain/balance_rules.dart';
import 'package:vfinance/domain/delete_blocked_exceptions.dart';
import 'package:vfinance/domain/finance_calendar_date.dart';
import 'package:vfinance/domain/finance_transaction_scope.dart';
import 'package:vfinance/domain/installment_rules.dart';
import 'package:vfinance/domain/invoice_rules.dart';
import 'package:vfinance/domain/transaction_enums.dart';
import 'package:vfinance/domain/year_backup_filter.dart';
import 'package:vfinance/domain/year_backup_snapshot.dart';

/// Thin Drift-backed repository; balance updates use [computeBalanceAfterTransaction].
class FinanceLocalRepository {
  FinanceLocalRepository(this._db);

  final AppDatabase _db;

  Future<int> insertAccount({
    required String name,
    required String type,
    int balanceInCents = 0,
  }) {
    return _db
        .into(_db.accounts)
        .insert(
          AccountsCompanion.insert(
            name: name,
            type: type,
            balanceInCents: balanceInCents,
          ),
        );
  }

  Future<Account?> getAccountById(int id) {
    return (_db.select(
      _db.accounts,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<void> updateAccount({
    required int id,
    required String name,
    required String type,
    required int balanceInCents,
  }) {
    return (_db.update(_db.accounts)..where((t) => t.id.equals(id))).write(
      AccountsCompanion(
        name: Value<String>(name),
        type: Value<String>(type),
        balanceInCents: Value<int>(balanceInCents),
      ),
    );
  }

  /// Deletes the account when no finance transaction references it.
  Future<void> deleteAccount(int id) async {
    final List<FinanceTransaction> linked = await (_db.select(
      _db.financeTransactions,
    )..where((t) => t.accountId.equals(id))).get();
    if (linked.isNotEmpty) {
      throw const AccountDeleteBlockedException();
    }
    await (_db.delete(_db.accounts)..where((t) => t.id.equals(id))).go();
  }

  Future<CreditCard?> getCreditCardById(int id) {
    return (_db.select(
      _db.creditCards,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<void> updateCreditCard({
    required int id,
    required String name,
    required int limitInCents,
    required int closingDay,
    required int dueDay,
  }) {
    return (_db.update(_db.creditCards)..where((t) => t.id.equals(id))).write(
      CreditCardsCompanion(
        name: Value<String>(name),
        limitInCents: Value<int>(limitInCents),
        closingDay: Value<int>(closingDay),
        dueDay: Value<int>(dueDay),
      ),
    );
  }

  /// Deletes the card when no transactions or invoices reference it.
  Future<void> deleteCreditCard(int id) async {
    final List<FinanceTransaction> tx = await (_db.select(
      _db.financeTransactions,
    )..where((t) => t.cardId.equals(id))).get();
    if (tx.isNotEmpty) {
      throw const CardDeleteBlockedException();
    }
    final List<Invoice> invs = await (_db.select(
      _db.invoices,
    )..where((i) => i.cardId.equals(id))).get();
    if (invs.isNotEmpty) {
      throw const CardDeleteBlockedException();
    }
    await (_db.delete(_db.creditCards)..where((t) => t.id.equals(id))).go();
  }

  Future<int> insertCreditCard({
    required String name,
    required int limitInCents,
    required int closingDay,
    required int dueDay,
  }) {
    return _db
        .into(_db.creditCards)
        .insert(
          CreditCardsCompanion.insert(
            name: name,
            limitInCents: limitInCents,
            closingDay: closingDay,
            dueDay: dueDay,
          ),
        );
  }

  Future<int> insertInvoice({
    required int cardId,
    required int month,
    required int year,
    required int totalInCents,
    int? adjustedTotalInCents,
    required bool isClosed,
    required bool isPaid,
  }) {
    return _db
        .into(_db.invoices)
        .insert(
          InvoicesCompanion.insert(
            cardId: cardId,
            month: month,
            year: year,
            totalInCents: totalInCents,
            adjustedTotalInCents: adjustedTotalInCents == null
                ? const Value.absent()
                : Value<int?>(adjustedTotalInCents),
            isClosed: isClosed,
            isPaid: isPaid,
          ),
        );
  }

  Future<Invoice?> getInvoiceById(int id) {
    return (_db.select(
      _db.invoices,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  /// Sets or clears [adjustedTotalInCents] for the invoice cycle, creating a
  /// row if needed. Recomputes [totalInCents] from credit transactions first.
  Future<void> upsertInvoiceAdjustment({
    required int cardId,
    required int month,
    required int year,
    int? adjustedTotalInCents,
  }) {
    return _db.transaction(() async {
      await _recomputeAllCreditInvoiceTotals();
      final Invoice? row =
          await (_db.select(_db.invoices)..where(
                ($InvoicesTable i) =>
                    i.cardId.equals(cardId) &
                    i.month.equals(month) &
                    i.year.equals(year),
              ))
              .getSingleOrNull();
      if (row == null) {
        await _db
            .into(_db.invoices)
            .insert(
              InvoicesCompanion.insert(
                cardId: cardId,
                month: month,
                year: year,
                totalInCents: 0,
                adjustedTotalInCents: adjustedTotalInCents == null
                    ? const Value.absent()
                    : Value<int?>(adjustedTotalInCents),
                isClosed: false,
                isPaid: false,
              ),
            );
        return;
      }
      await (_db.update(
        _db.invoices,
      )..where(($InvoicesTable i) => i.id.equals(row.id))).write(
        InvoicesCompanion(
          adjustedTotalInCents: adjustedTotalInCents == null
              ? const Value<int?>(null)
              : Value<int?>(adjustedTotalInCents),
        ),
      );
    });
  }

  /// Inserts a row and updates [accountId] balance when payment is not
  /// credit and [accountId] is non-null. Credit-card expenses trigger a full
  /// invoice total recomputation from transactions.
  Future<int> insertFinanceTransaction({
    required int amountInCents,
    required TransactionType transactionType,
    required String category,
    required String description,
    required DateTime dateUtc,
    required PaymentMethod paymentMethod,
    int? accountId,
    int? cardId,
    int? installmentId,
  }) {
    return _db.transaction(() async {
      final int rowId = await _db
          .into(_db.financeTransactions)
          .insert(
            FinanceTransactionsCompanion.insert(
              amountInCents: amountInCents,
              transactionType: transactionType.storageName,
              category: category,
              description: description,
              dateUtcMillis: dateUtc.millisecondsSinceEpoch,
              paymentMethod: paymentMethod.storageName,
              accountId: Value<int?>(accountId),
              cardId: Value<int?>(cardId),
              installmentId: Value<int?>(installmentId),
            ),
          );
      await _applyFinanceTransactionEffects(
        amountInCents: amountInCents,
        transactionType: transactionType,
        paymentMethod: paymentMethod,
        dateUtc: dateUtc,
        accountId: accountId,
        cardId: cardId,
      );
      await _recomputeAllCreditInvoiceTotals();
      return rowId;
    });
  }

  /// Inserts [installmentCount] credit-card expense rows for one purchase:
  /// [totalAmountInCents] is split across installments; dates advance by
  /// calendar month from [firstPurchaseDate]. All rows share the same
  /// [installmentId] (the autoincrement id of the first row).
  ///
  /// [rowDescriptions] must have length [installmentCount].
  Future<List<int>> insertCreditCardInstallmentExpensePlan({
    required int totalAmountInCents,
    required int installmentCount,
    required String category,
    required List<String> rowDescriptions,
    required DateTime firstPurchaseDate,
    required int cardId,
  }) {
    if (rowDescriptions.length != installmentCount) {
      throw ArgumentError(
        'rowDescriptions.length (${rowDescriptions.length}) '
        'must equal installmentCount ($installmentCount)',
      );
    }
    return _db.transaction(() async {
      final List<PlannedCreditInstallmentCharge> plan =
          planCreditInstallmentCharges(
            installmentGroupId: 0,
            totalAmountInCents: totalAmountInCents,
            installmentCount: installmentCount,
            firstPurchaseDate: firstPurchaseDate,
          );
      final List<int> ids = <int>[];
      int? installmentGroupId;
      for (int i = 0; i < plan.length; i++) {
        final PlannedCreditInstallmentCharge c = plan[i];
        final int rowId = await _db
            .into(_db.financeTransactions)
            .insert(
              FinanceTransactionsCompanion.insert(
                amountInCents: c.amountInCents,
                transactionType: TransactionType.expense.storageName,
                category: category,
                description: rowDescriptions[i],
                dateUtcMillis: c.purchaseDate.millisecondsSinceEpoch,
                paymentMethod: PaymentMethod.credit.storageName,
                cardId: Value<int>(cardId),
                installmentId: Value<int?>(installmentGroupId),
              ),
            );
        ids.add(rowId);
        if (i == 0) {
          installmentGroupId = rowId;
          await (_db.update(
            _db.financeTransactions,
          )..where((t) => t.id.equals(rowId))).write(
            FinanceTransactionsCompanion(
              installmentId: Value<int?>(installmentGroupId),
            ),
          );
        }
      }
      await _recomputeAllCreditInvoiceTotals();
      return ids;
    });
  }

  Future<FinanceTransaction?> getFinanceTransactionById(int id) {
    return (_db.select(
      _db.financeTransactions,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  /// Replaces row data and reapplies balance / invoice side effects.
  Future<void> updateFinanceTransaction({
    required int id,
    required int amountInCents,
    required TransactionType transactionType,
    required String category,
    required String description,
    required DateTime dateUtc,
    required PaymentMethod paymentMethod,
    int? accountId,
    int? cardId,
  }) {
    return _db.transaction(() async {
      final FinanceTransaction? old = await getFinanceTransactionById(id);
      if (old == null) {
        throw StateError('Transaction not found: $id');
      }
      await _undoFinanceTransactionEffects(old);
      await (_db.update(
        _db.financeTransactions,
      )..where((t) => t.id.equals(id))).write(
        FinanceTransactionsCompanion(
          amountInCents: Value<int>(amountInCents),
          transactionType: Value<String>(transactionType.storageName),
          category: Value<String>(category),
          description: Value<String>(description),
          dateUtcMillis: Value<int>(dateUtc.millisecondsSinceEpoch),
          paymentMethod: Value<String>(paymentMethod.storageName),
          accountId: Value<int?>(accountId),
          cardId: Value<int?>(cardId),
        ),
      );
      await _applyFinanceTransactionEffects(
        amountInCents: amountInCents,
        transactionType: transactionType,
        paymentMethod: paymentMethod,
        dateUtc: dateUtc,
        accountId: accountId,
        cardId: cardId,
      );
      await _recomputeAllCreditInvoiceTotals();
    });
  }

  /// Removes the row after reversing balance / invoice side effects.
  Future<void> deleteFinanceTransaction(int id) {
    return _db.transaction(() async {
      final FinanceTransaction? old = await getFinanceTransactionById(id);
      if (old == null) {
        return;
      }
      await _undoFinanceTransactionEffects(old);
      await (_db.delete(
        _db.financeTransactions,
      )..where((t) => t.id.equals(id))).go();
      await _recomputeAllCreditInvoiceTotals();
    });
  }

  Future<void> _applyFinanceTransactionEffects({
    required int amountInCents,
    required TransactionType transactionType,
    required PaymentMethod paymentMethod,
    required DateTime dateUtc,
    int? accountId,
    int? cardId,
  }) async {
    final bool shouldTouchAccount =
        paymentMethod != PaymentMethod.credit && accountId != null;
    if (shouldTouchAccount) {
      final Account? row = await getAccountById(accountId);
      if (row == null) {
        throw StateError('Account not found: $accountId');
      }
      final int next = computeBalanceAfterTransaction(
        accountBalanceInCents: row.balanceInCents,
        transactionAmountInCents: amountInCents,
        transactionType: transactionType,
        paymentMethod: paymentMethod,
      );
      await (_db.update(_db.accounts)..where((t) => t.id.equals(accountId)))
          .write(AccountsCompanion(balanceInCents: Value<int>(next)));
    }
  }

  Future<void> _undoFinanceTransactionEffects(FinanceTransaction row) async {
    final TransactionType transactionType = TransactionType.parseStorage(
      row.transactionType,
    );
    final PaymentMethod paymentMethod = PaymentMethod.parseStorage(
      row.paymentMethod,
    );
    final bool shouldTouchAccount =
        paymentMethod != PaymentMethod.credit && row.accountId != null;
    if (shouldTouchAccount) {
      final int accountId = row.accountId!;
      final Account? acc = await getAccountById(accountId);
      if (acc == null) {
        throw StateError('Account not found: $accountId');
      }
      final int next = computeBalanceAfterRemovingTransaction(
        accountBalanceInCents: acc.balanceInCents,
        transactionAmountInCents: row.amountInCents,
        transactionType: transactionType,
        paymentMethod: paymentMethod,
      );
      await (_db.update(_db.accounts)..where((t) => t.id.equals(accountId)))
          .write(AccountsCompanion(balanceInCents: Value<int>(next)));
    }
  }

  Future<void> _dedupeInvoicesByCycle() async {
    final List<Invoice> all = await _db.select(_db.invoices).get();
    final Map<String, List<Invoice>> byKey = <String, List<Invoice>>{};
    for (final Invoice i in all) {
      final String k = '${i.cardId}|${i.year}|${i.month}';
      byKey.putIfAbsent(k, () => <Invoice>[]).add(i);
    }
    for (final List<Invoice> group in byKey.values) {
      if (group.length < 2) {
        continue;
      }
      group.sort((Invoice a, Invoice b) => a.id.compareTo(b.id));
      final Invoice keep = group.first;
      int? mergedAdj = keep.adjustedTotalInCents;
      for (final Invoice dup in group.skip(1)) {
        mergedAdj ??= dup.adjustedTotalInCents;
      }
      if (mergedAdj != keep.adjustedTotalInCents) {
        await (_db.update(
          _db.invoices,
        )..where(($InvoicesTable i) => i.id.equals(keep.id))).write(
          InvoicesCompanion(adjustedTotalInCents: Value<int?>(mergedAdj)),
        );
      }
      for (final Invoice dup in group.skip(1)) {
        await (_db.delete(
          _db.invoices,
        )..where(($InvoicesTable i) => i.id.equals(dup.id))).go();
      }
    }
  }

  /// Rebuilds every invoice [totalInCents] from credit-card expense
  /// transactions; preserves [adjustedTotalInCents], [isPaid], [isClosed].
  Future<void> _recomputeAllCreditInvoiceTotals() async {
    await _dedupeInvoicesByCycle();
    final List<FinanceTransaction> allTx = await _db
        .select(_db.financeTransactions)
        .get();
    final List<CreditCard> cards = await _db.select(_db.creditCards).get();
    final Map<int, CreditCard> cardById = <int, CreditCard>{
      for (final CreditCard c in cards) c.id: c,
    };
    final Map<String, int> sums = <String, int>{};
    for (final FinanceTransaction t in allTx) {
      if (t.transactionType != TransactionType.expense.storageName) {
        continue;
      }
      if (t.paymentMethod != PaymentMethod.credit.storageName) {
        continue;
      }
      if (t.cardId == null) {
        continue;
      }
      final CreditCard? card = cardById[t.cardId!];
      if (card == null) {
        continue;
      }
      final DateTime civil = localCivilDateFromFinanceEpochMillis(
        t.dateUtcMillis,
      );
      final InvoiceCycleMonth cycle = computeInvoiceCycleMonth(
        purchaseDate: civil,
        closingDay: card.closingDay,
      );
      final String key = '${t.cardId}|${cycle.year}|${cycle.month}';
      sums[key] = (sums[key] ?? 0) + t.amountInCents;
    }
    final List<Invoice> existing = await _db.select(_db.invoices).get();
    for (final Invoice inv in existing) {
      final String key = '${inv.cardId}|${inv.year}|${inv.month}';
      final int newTotal = sums[key] ?? 0;
      sums.remove(key);
      await (_db.update(_db.invoices)
            ..where(($InvoicesTable i) => i.id.equals(inv.id)))
          .write(InvoicesCompanion(totalInCents: Value<int>(newTotal)));
    }
    for (final MapEntry<String, int> e in sums.entries) {
      if (e.value <= 0) {
        continue;
      }
      final List<String> parts = e.key.split('|');
      if (parts.length != 3) {
        continue;
      }
      final int cardId = int.parse(parts[0]);
      final int year = int.parse(parts[1]);
      final int month = int.parse(parts[2]);
      await _db
          .into(_db.invoices)
          .insert(
            InvoicesCompanion.insert(
              cardId: cardId,
              month: month,
              year: year,
              totalInCents: e.value,
              isClosed: false,
              isPaid: false,
            ),
          );
    }
  }

  /// Single shared stream per query so multiple [StreamBuilder]s (e.g. shell
  /// tabs) do not each create a new Drift `.watch()` mapping chain.
  late final Stream<List<Account>> _watchAccounts = (_db.select(
    _db.accounts,
  )..orderBy([(row) => OrderingTerm.asc(row.name)])).watch();

  late final Stream<List<FinanceTransaction>> _watchFinanceTransactions =
      (_db.select(
        _db.financeTransactions,
      )..orderBy([(row) => OrderingTerm.desc(row.dateUtcMillis)])).watch();

  late final Stream<List<CreditCard>> _watchCreditCards = (_db.select(
    _db.creditCards,
  )..orderBy([(row) => OrderingTerm.asc(row.name)])).watch();

  late final Stream<List<Invoice>> _watchInvoices =
      (_db.select(_db.invoices)..orderBy([
            (row) => OrderingTerm.desc(row.year),
            (row) => OrderingTerm.desc(row.month),
          ]))
          .watch();

  /// Emits all accounts ordered by name whenever the table changes.
  Stream<List<Account>> watchAccounts() => _watchAccounts;

  /// Emits finance transactions newest-first.
  Stream<List<FinanceTransaction>> watchFinanceTransactions() =>
      _watchFinanceTransactions;

  /// Emits postings for **Lançamentos** (excludes credit-card expenses).
  Stream<List<FinanceTransaction>> watchLedgerFinanceTransactions() {
    return _watchFinanceTransactions.map(
      (List<FinanceTransaction> rows) => rows
          .where(
            (FinanceTransaction t) => !isCardCreditExpenseStorage(
              transactionTypeStorage: t.transactionType,
              paymentMethodStorage: t.paymentMethod,
              cardId: t.cardId,
            ),
          )
          .toList(),
    );
  }

  /// Emits credit cards ordered by name.
  Stream<List<CreditCard>> watchCreditCards() => _watchCreditCards;

  /// Emits invoices newest by year/month.
  Stream<List<Invoice>> watchInvoices() => _watchInvoices;

  /// Builds a JSON backup snapshot for [year] (full accounts/cards + filtered
  /// tx and invoices), matching [importYearBackupSnapshot] expectations.
  Future<YearBackupSnapshot> buildYearBackupForCalendarYear(int year) async {
    final List<Account> accounts = await _db.select(_db.accounts).get();
    final List<CreditCard> cards = await _db.select(_db.creditCards).get();
    final List<FinanceTransaction> txs = await _db
        .select(_db.financeTransactions)
        .get();
    final List<Invoice> invs = await _db.select(_db.invoices).get();
    return buildYearBackupSnapshotForYear(
      schemaVersion: 1,
      year: year,
      accounts: accounts.map(_toYearBackupAccount).toList(),
      creditCards: cards.map(_toYearBackupCreditCard).toList(),
      financeTransactions: txs.map(_toYearBackupFinanceTransaction).toList(),
      invoices: invs.map(_toYearBackupInvoice).toList(),
    );
  }

  /// Replaces finance transactions in [snapshot.year] and invoices with
  /// that billing year, then upserts accounts/cards and inserts rows from
  /// [snapshot] (see [domain.md] restore policy).
  Future<void> importYearBackupSnapshot(YearBackupSnapshot snapshot) async {
    _validateYearBackupSnapshot(snapshot);
    await _db.transaction(() async {
      await _deleteFinanceTransactionsInUtcCalendarYear(snapshot.year);
      await _deleteInvoicesForBillingYear(snapshot.year);
      for (final YearBackupAccount a in snapshot.accounts) {
        await _db
            .into(_db.accounts)
            .insert(
              AccountsCompanion.insert(
                id: Value<int>(a.id),
                name: a.name,
                type: a.type,
                balanceInCents: a.balanceInCents,
              ),
              mode: InsertMode.insertOrReplace,
            );
      }
      for (final YearBackupCreditCard c in snapshot.creditCards) {
        await _db
            .into(_db.creditCards)
            .insert(
              CreditCardsCompanion.insert(
                id: Value<int>(c.id),
                name: c.name,
                limitInCents: c.limitInCents,
                closingDay: c.closingDay,
                dueDay: c.dueDay,
              ),
              mode: InsertMode.insertOrReplace,
            );
      }
      for (final YearBackupFinanceTransaction t
          in snapshot.financeTransactions) {
        await _db
            .into(_db.financeTransactions)
            .insert(
              FinanceTransactionsCompanion.insert(
                id: Value<int>(t.id),
                amountInCents: t.amountInCents,
                transactionType: t.transactionTypeStorage,
                category: t.category,
                description: t.description,
                dateUtcMillis: t.dateUtcMillis,
                paymentMethod: t.paymentMethodStorage,
                accountId: _nullableFkCompanion(t.accountId),
                cardId: _nullableFkCompanion(t.cardId),
                installmentId: _nullableFkCompanion(t.installmentId),
              ),
            );
      }
      for (final YearBackupInvoice i in snapshot.invoices) {
        await _db
            .into(_db.invoices)
            .insert(
              InvoicesCompanion.insert(
                id: Value<int>(i.id),
                cardId: i.cardId,
                month: i.month,
                year: i.year,
                totalInCents: i.totalInCents,
                adjustedTotalInCents: i.adjustedTotalInCents == null
                    ? const Value.absent()
                    : Value<int?>(i.adjustedTotalInCents),
                isClosed: i.isClosed,
                isPaid: i.isPaid,
              ),
            );
      }
      await _recomputeAllCreditInvoiceTotals();
    });
  }

  /// Deletes every row in all tables (accounts, cards, transactions, invoices).
  Future<void> clearAllLocalData() async {
    await _db.transaction(() async {
      await _db.delete(_db.financeTransactions).go();
      await _db.delete(_db.invoices).go();
      await _db.delete(_db.accounts).go();
      await _db.delete(_db.creditCards).go();
    });
  }

  Future<int> _deleteFinanceTransactionsInUtcCalendarYear(int year) {
    final int start = DateTime.utc(year).millisecondsSinceEpoch;
    final int end = DateTime.utc(year + 1).millisecondsSinceEpoch;
    return (_db.delete(_db.financeTransactions)..where(
          ($FinanceTransactionsTable t) =>
              t.dateUtcMillis.isBiggerOrEqualValue(start) &
              t.dateUtcMillis.isSmallerThanValue(end),
        ))
        .go();
  }

  Future<int> _deleteInvoicesForBillingYear(int year) {
    return (_db.delete(
      _db.invoices,
    )..where(($InvoicesTable t) => t.year.equals(year))).go();
  }
}

YearBackupAccount _toYearBackupAccount(Account row) {
  return YearBackupAccount(
    id: row.id,
    name: row.name,
    type: row.type,
    balanceInCents: row.balanceInCents,
  );
}

YearBackupCreditCard _toYearBackupCreditCard(CreditCard row) {
  return YearBackupCreditCard(
    id: row.id,
    name: row.name,
    limitInCents: row.limitInCents,
    closingDay: row.closingDay,
    dueDay: row.dueDay,
  );
}

YearBackupFinanceTransaction _toYearBackupFinanceTransaction(
  FinanceTransaction row,
) {
  return YearBackupFinanceTransaction(
    id: row.id,
    amountInCents: row.amountInCents,
    transactionTypeStorage: row.transactionType,
    category: row.category,
    description: row.description,
    dateUtcMillis: row.dateUtcMillis,
    paymentMethodStorage: row.paymentMethod,
    accountId: row.accountId,
    cardId: row.cardId,
    installmentId: row.installmentId,
  );
}

YearBackupInvoice _toYearBackupInvoice(Invoice row) {
  return YearBackupInvoice(
    id: row.id,
    cardId: row.cardId,
    month: row.month,
    year: row.year,
    totalInCents: row.totalInCents,
    adjustedTotalInCents: row.adjustedTotalInCents,
    isClosed: row.isClosed,
    isPaid: row.isPaid,
  );
}

Value<int?> _nullableFkCompanion(int? id) {
  if (id == null) {
    return const Value.absent();
  }
  return Value<int?>(id);
}

void _validateYearBackupSnapshot(YearBackupSnapshot snapshot) {
  for (final YearBackupFinanceTransaction t in snapshot.financeTransactions) {
    final int utcYear = DateTime.fromMillisecondsSinceEpoch(
      t.dateUtcMillis,
      isUtc: true,
    ).year;
    if (utcYear != snapshot.year) {
      throw ArgumentError(
        'Transaction ${t.id} has UTC year $utcYear '
        'but snapshot.year is ${snapshot.year}',
      );
    }
  }
  for (final YearBackupInvoice i in snapshot.invoices) {
    if (i.year != snapshot.year) {
      throw ArgumentError(
        'Invoice ${i.id} has year ${i.year} '
        'but snapshot.year is ${snapshot.year}',
      );
    }
  }
}

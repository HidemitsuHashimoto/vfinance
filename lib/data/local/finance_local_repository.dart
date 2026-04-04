import 'package:drift/drift.dart';
import 'package:vfinance/data/local/app_database.dart';
import 'package:vfinance/domain/balance_rules.dart';
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

  /// Inserts a row and updates [accountId] balance when payment is not
  /// credit and [accountId] is non-null. Credit-card expenses update the
  /// matching invoice cycle total for [cardId].
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
      final bool isCreditExpense =
          paymentMethod == PaymentMethod.credit &&
          transactionType == TransactionType.expense &&
          cardId != null;
      if (isCreditExpense) {
        await _addCreditExpenseToInvoiceCycle(
          cardId: cardId,
          purchaseDateUtc: dateUtc,
          deltaCents: amountInCents,
        );
      }
      return rowId;
    });
  }

  Future<void> _addCreditExpenseToInvoiceCycle({
    required int cardId,
    required DateTime purchaseDateUtc,
    required int deltaCents,
  }) async {
    final CreditCard? card = await (_db.select(
      _db.creditCards,
    )..where((t) => t.id.equals(cardId))).getSingleOrNull();
    if (card == null) {
      throw StateError('Card not found: $cardId');
    }
    final InvoiceCycleMonth cycle = computeInvoiceCycleMonth(
      purchaseDate: purchaseDateUtc,
      closingDay: card.closingDay,
    );
    final Invoice? existing =
        await (_db.select(_db.invoices)..where(
              (i) =>
                  i.cardId.equals(cardId) &
                  i.month.equals(cycle.month) &
                  i.year.equals(cycle.year),
            ))
            .getSingleOrNull();
    if (existing == null) {
      await _db
          .into(_db.invoices)
          .insert(
            InvoicesCompanion.insert(
              cardId: cardId,
              month: cycle.month,
              year: cycle.year,
              totalInCents: deltaCents,
              isClosed: false,
              isPaid: false,
            ),
          );
      return;
    }
    final int newTotal = existing.totalInCents + deltaCents;
    final int? newAdjusted = existing.adjustedTotalInCents == null
        ? null
        : existing.adjustedTotalInCents! + deltaCents;
    await (_db.update(
      _db.invoices,
    )..where((i) => i.id.equals(existing.id))).write(
      InvoicesCompanion(
        totalInCents: Value<int>(newTotal),
        adjustedTotalInCents: newAdjusted == null
            ? const Value.absent()
            : Value<int?>(newAdjusted),
      ),
    );
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

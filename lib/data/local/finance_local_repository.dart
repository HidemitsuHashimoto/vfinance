import 'package:drift/drift.dart';
import 'package:vfinance/data/local/app_database.dart';
import 'package:vfinance/domain/balance_rules.dart';
import 'package:vfinance/domain/transaction_enums.dart';
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
  /// credit and [accountId] is non-null.
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
      return rowId;
    });
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

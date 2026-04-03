import 'package:drift/drift.dart';
import 'package:vfinance/data/local/app_database.dart';
import 'package:vfinance/domain/balance_rules.dart';
import 'package:vfinance/domain/transaction_enums.dart';

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
}

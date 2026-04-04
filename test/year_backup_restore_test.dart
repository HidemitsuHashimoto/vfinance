import 'package:flutter_test/flutter_test.dart';
import 'package:vfinance/data/local/app_database.dart';
import 'package:vfinance/data/local/finance_local_repository.dart';
import 'package:vfinance/domain/transaction_enums.dart';
import 'package:vfinance/domain/year_backup_snapshot.dart';

void main() {
  test('importYearBackupSnapshot deletes target year then inserts without '
      'touching other years', () async {
    final AppDatabase db = AppDatabase.memory();
    addTearDown(db.close);
    final FinanceLocalRepository repo = FinanceLocalRepository(db);
    final int accountId = await repo.insertAccount(
      name: 'C',
      type: 'checking',
      balanceInCents: 0,
    );
    final int cardId = await repo.insertCreditCard(
      name: 'Card',
      limitInCents: 1,
      closingDay: 1,
      dueDay: 2,
    );
    await repo.insertFinanceTransaction(
      amountInCents: 100,
      transactionType: TransactionType.expense,
      category: 'a',
      description: '2024',
      dateUtc: DateTime.utc(2024, 6, 1),
      paymentMethod: PaymentMethod.debit,
      accountId: accountId,
    );
    await repo.insertFinanceTransaction(
      amountInCents: 200,
      transactionType: TransactionType.expense,
      category: 'b',
      description: '2025-old',
      dateUtc: DateTime.utc(2025, 3, 1),
      paymentMethod: PaymentMethod.debit,
      accountId: accountId,
    );
    final int invOld = await repo.insertInvoice(
      cardId: cardId,
      month: 3,
      year: 2025,
      totalInCents: 50,
      adjustedTotalInCents: null,
      isClosed: false,
      isPaid: false,
    );
    expect(invOld, greaterThan(0));
    final YearBackupSnapshot snapshot = YearBackupSnapshot(
      schemaVersion: 1,
      year: 2025,
      accounts: <YearBackupAccount>[
        YearBackupAccount(
          id: accountId,
          name: 'C',
          type: 'checking',
          balanceInCents: 0,
        ),
      ],
      creditCards: <YearBackupCreditCard>[
        YearBackupCreditCard(
          id: cardId,
          name: 'Card',
          limitInCents: 1,
          closingDay: 1,
          dueDay: 2,
        ),
      ],
      financeTransactions: <YearBackupFinanceTransaction>[
        YearBackupFinanceTransaction(
          id: 99,
          amountInCents: 777,
          transactionTypeStorage: 'EXPENSE',
          category: 'x',
          description: '2025-new',
          dateUtcMillis: DateTime.utc(2025, 7, 1).millisecondsSinceEpoch,
          paymentMethodStorage: 'DEBIT',
          accountId: accountId,
          cardId: null,
          installmentId: null,
        ),
      ],
      invoices: <YearBackupInvoice>[
        YearBackupInvoice(
          id: 88,
          cardId: cardId,
          month: 7,
          year: 2025,
          totalInCents: 300,
          adjustedTotalInCents: 290,
          isClosed: true,
          isPaid: false,
        ),
      ],
    );
    await repo.importYearBackupSnapshot(snapshot);
    final List<FinanceTransaction> txRows = await db
        .select(db.financeTransactions)
        .get();
    final List<Invoice> invRows = await db.select(db.invoices).get();
    expect(txRows, hasLength(2));
    expect(
      txRows.map((FinanceTransaction e) => e.description).toSet(),
      <String>{'2024', '2025-new'},
    );
    expect(invRows, hasLength(1));
    expect(invRows.single.id, 88);
    expect(
      invRows.single.totalInCents,
      0,
      reason:
          'invoice totals are recomputed from credit transactions on import',
    );
    expect(invRows.single.adjustedTotalInCents, 290);
  });
}

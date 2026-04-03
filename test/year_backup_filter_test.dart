import 'package:flutter_test/flutter_test.dart';
import 'package:vfinance/domain/year_backup_filter.dart';
import 'package:vfinance/domain/year_backup_snapshot.dart';

void main() {
  test('buildYearBackupSnapshotForYear keeps only matching transactions', () {
    final YearBackupSnapshot snapshot = buildYearBackupSnapshotForYear(
      schemaVersion: 1,
      year: 2025,
      accounts: const <YearBackupAccount>[],
      creditCards: const <YearBackupCreditCard>[],
      financeTransactions: <YearBackupFinanceTransaction>[
        YearBackupFinanceTransaction(
          id: 1,
          amountInCents: 100,
          transactionTypeStorage: 'EXPENSE',
          category: 'a',
          description: 'a',
          dateUtcMillis: DateTime.utc(2025, 6, 1).millisecondsSinceEpoch,
          paymentMethodStorage: 'PIX',
          accountId: 1,
          cardId: null,
          installmentId: null,
        ),
        YearBackupFinanceTransaction(
          id: 2,
          amountInCents: 200,
          transactionTypeStorage: 'INCOME',
          category: 'b',
          description: 'b',
          dateUtcMillis: DateTime.utc(2024, 12, 31).millisecondsSinceEpoch,
          paymentMethodStorage: 'PIX',
          accountId: 1,
          cardId: null,
          installmentId: null,
        ),
      ],
      invoices: <YearBackupInvoice>[
        YearBackupInvoice(
          id: 1,
          cardId: 1,
          month: 12,
          year: 2024,
          totalInCents: 1,
          adjustedTotalInCents: null,
          isClosed: false,
          isPaid: false,
        ),
        YearBackupInvoice(
          id: 2,
          cardId: 1,
          month: 3,
          year: 2025,
          totalInCents: 2,
          adjustedTotalInCents: null,
          isClosed: false,
          isPaid: false,
        ),
      ],
    );
    expect(snapshot.financeTransactions, hasLength(1));
    expect(snapshot.financeTransactions.single.id, 1);
    expect(snapshot.invoices, hasLength(1));
    expect(snapshot.invoices.single.year, 2025);
  });
}

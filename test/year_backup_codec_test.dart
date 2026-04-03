import 'package:flutter_test/flutter_test.dart';
import 'package:vfinance/domain/year_backup_codec.dart';
import 'package:vfinance/domain/year_backup_snapshot.dart';

void main() {
  test('round-trip preserves representative snapshot', () {
    final YearBackupSnapshot original = YearBackupSnapshot(
      schemaVersion: 1,
      year: 2025,
      accounts: <YearBackupAccount>[
        YearBackupAccount(
          id: 1,
          name: 'Checking',
          type: 'checking',
          balanceInCents: 12_345,
        ),
      ],
      creditCards: <YearBackupCreditCard>[
        YearBackupCreditCard(
          id: 10,
          name: 'Visa',
          limitInCents: 50_000_00,
          closingDay: 10,
          dueDay: 17,
        ),
      ],
      financeTransactions: <YearBackupFinanceTransaction>[
        YearBackupFinanceTransaction(
          id: 100,
          amountInCents: 999,
          transactionTypeStorage: 'EXPENSE',
          category: 'food',
          description: 'lunch',
          dateUtcMillis: DateTime.utc(2025, 1, 2).millisecondsSinceEpoch,
          paymentMethodStorage: 'DEBIT',
          accountId: 1,
          cardId: null,
          installmentId: null,
        ),
        YearBackupFinanceTransaction(
          id: 101,
          amountInCents: 2_000,
          transactionTypeStorage: 'EXPENSE',
          category: 'shop',
          description: 'credit',
          dateUtcMillis: DateTime.utc(2025, 1, 3).millisecondsSinceEpoch,
          paymentMethodStorage: 'CREDIT',
          accountId: null,
          cardId: 10,
          installmentId: 7,
        ),
      ],
      invoices: <YearBackupInvoice>[
        YearBackupInvoice(
          id: 50,
          cardId: 10,
          month: 1,
          year: 2025,
          totalInCents: 5_000,
          adjustedTotalInCents: 4_800,
          isClosed: true,
          isPaid: false,
        ),
      ],
    );
    final String json = encodeYearBackupSnapshot(original);
    final YearBackupSnapshot restored = decodeYearBackupSnapshot(json);
    expect(restored, original);
  });
}

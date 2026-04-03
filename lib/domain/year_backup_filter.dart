import 'package:vfinance/domain/year_backup_snapshot.dart';

bool _isUtcMillisInCalendarYear(int millis, int year) {
  return DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true).year == year;
}

/// Builds a [YearBackupSnapshot] for [year] from full lists (export helper).
YearBackupSnapshot buildYearBackupSnapshotForYear({
  required int schemaVersion,
  required int year,
  required List<YearBackupAccount> accounts,
  required List<YearBackupCreditCard> creditCards,
  required List<YearBackupFinanceTransaction> financeTransactions,
  required List<YearBackupInvoice> invoices,
}) {
  return YearBackupSnapshot(
    schemaVersion: schemaVersion,
    year: year,
    accounts: accounts,
    creditCards: creditCards,
    financeTransactions: financeTransactions
        .where(
          (YearBackupFinanceTransaction t) =>
              _isUtcMillisInCalendarYear(t.dateUtcMillis, year),
        )
        .toList(),
    invoices: invoices.where((YearBackupInvoice i) => i.year == year).toList(),
  );
}

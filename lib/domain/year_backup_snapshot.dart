import 'package:meta/meta.dart';

/// One account row in a per-year JSON backup ([domain.md]).
@immutable
class YearBackupAccount {
  const YearBackupAccount({
    required this.id,
    required this.name,
    required this.type,
    required this.balanceInCents,
  });

  final int id;
  final String name;
  final String type;
  final int balanceInCents;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is YearBackupAccount &&
        id == other.id &&
        name == other.name &&
        type == other.type &&
        balanceInCents == other.balanceInCents;
  }

  @override
  int get hashCode => Object.hash(id, name, type, balanceInCents);
}

/// One credit card row in a per-year JSON backup.
@immutable
class YearBackupCreditCard {
  const YearBackupCreditCard({
    required this.id,
    required this.name,
    required this.limitInCents,
    required this.closingDay,
    required this.dueDay,
  });

  final int id;
  final String name;
  final int limitInCents;
  final int closingDay;
  final int dueDay;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is YearBackupCreditCard &&
        id == other.id &&
        name == other.name &&
        limitInCents == other.limitInCents &&
        closingDay == other.closingDay &&
        dueDay == other.dueDay;
  }

  @override
  int get hashCode => Object.hash(id, name, limitInCents, closingDay, dueDay);
}

/// One finance transaction row in backup JSON (enums as storage strings).
@immutable
class YearBackupFinanceTransaction {
  const YearBackupFinanceTransaction({
    required this.id,
    required this.amountInCents,
    required this.transactionTypeStorage,
    required this.category,
    required this.description,
    required this.dateUtcMillis,
    required this.paymentMethodStorage,
    required this.accountId,
    required this.cardId,
    required this.installmentId,
  });

  final int id;
  final int amountInCents;
  final String transactionTypeStorage;
  final String category;
  final String description;
  final int dateUtcMillis;
  final String paymentMethodStorage;
  final int? accountId;
  final int? cardId;
  final int? installmentId;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is YearBackupFinanceTransaction &&
        id == other.id &&
        amountInCents == other.amountInCents &&
        transactionTypeStorage == other.transactionTypeStorage &&
        category == other.category &&
        description == other.description &&
        dateUtcMillis == other.dateUtcMillis &&
        paymentMethodStorage == other.paymentMethodStorage &&
        accountId == other.accountId &&
        cardId == other.cardId &&
        installmentId == other.installmentId;
  }

  @override
  int get hashCode => Object.hash(
    id,
    amountInCents,
    transactionTypeStorage,
    category,
    description,
    dateUtcMillis,
    paymentMethodStorage,
    accountId,
    cardId,
    installmentId,
  );
}

/// One invoice row in backup JSON.
@immutable
class YearBackupInvoice {
  const YearBackupInvoice({
    required this.id,
    required this.cardId,
    required this.month,
    required this.year,
    required this.totalInCents,
    required this.adjustedTotalInCents,
    required this.isClosed,
    required this.isPaid,
  });

  final int id;
  final int cardId;
  final int month;
  final int year;
  final int totalInCents;
  final int? adjustedTotalInCents;
  final bool isClosed;
  final bool isPaid;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is YearBackupInvoice &&
        id == other.id &&
        cardId == other.cardId &&
        month == other.month &&
        year == other.year &&
        totalInCents == other.totalInCents &&
        adjustedTotalInCents == other.adjustedTotalInCents &&
        isClosed == other.isClosed &&
        isPaid == other.isPaid;
  }

  @override
  int get hashCode => Object.hash(
    id,
    cardId,
    month,
    year,
    totalInCents,
    adjustedTotalInCents,
    isClosed,
    isPaid,
  );
}

/// Portable snapshot for export/import of one calendar/billing year.
@immutable
class YearBackupSnapshot {
  const YearBackupSnapshot({
    required this.schemaVersion,
    required this.year,
    required this.accounts,
    required this.creditCards,
    required this.financeTransactions,
    required this.invoices,
  });

  final int schemaVersion;
  final int year;
  final List<YearBackupAccount> accounts;
  final List<YearBackupCreditCard> creditCards;
  final List<YearBackupFinanceTransaction> financeTransactions;
  final List<YearBackupInvoice> invoices;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! YearBackupSnapshot) {
      return false;
    }
    if (schemaVersion != other.schemaVersion || year != other.year) {
      return false;
    }
    if (!_listEquals(accounts, other.accounts)) {
      return false;
    }
    if (!_listEquals(creditCards, other.creditCards)) {
      return false;
    }
    if (!_listEquals(financeTransactions, other.financeTransactions)) {
      return false;
    }
    if (!_listEquals(invoices, other.invoices)) {
      return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
    schemaVersion,
    year,
    Object.hashAll(accounts.map((YearBackupAccount e) => e.hashCode)),
    Object.hashAll(creditCards.map((YearBackupCreditCard e) => e.hashCode)),
    Object.hashAll(
      financeTransactions.map((YearBackupFinanceTransaction e) => e.hashCode),
    ),
    Object.hashAll(invoices.map((YearBackupInvoice e) => e.hashCode)),
  );
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (a.length != b.length) {
    return false;
  }
  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) {
      return false;
    }
  }
  return true;
}

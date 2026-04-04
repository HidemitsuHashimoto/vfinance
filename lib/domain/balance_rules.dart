import 'package:vfinance/domain/transaction_enums.dart';

/// One open invoice amount for [computeTotalUserBalance].
///
/// Uses [adjustedTotalInCents] when non-null; otherwise [totalInCents],
/// matching [domain.md].
final class OpenInvoiceBalanceInput {
  const OpenInvoiceBalanceInput({
    required this.totalInCents,
    this.adjustedTotalInCents,
  });

  final int totalInCents;
  final int? adjustedTotalInCents;

  int get effectiveTotalInCents => adjustedTotalInCents ?? totalInCents;
}

/// New account balance after recording [transactionType] / [paymentMethod].
///
/// [transactionAmountInCents] is treated as a non-negative magnitude; behavior
/// for negative amounts is undefined.
///
/// Credit card spending does not change the account balance ([domain.md]).
int computeBalanceAfterTransaction({
  required int accountBalanceInCents,
  required int transactionAmountInCents,
  required TransactionType transactionType,
  required PaymentMethod paymentMethod,
}) {
  if (paymentMethod == PaymentMethod.credit) {
    return accountBalanceInCents;
  }
  return switch (transactionType) {
    TransactionType.expense => accountBalanceInCents - transactionAmountInCents,
    TransactionType.income => accountBalanceInCents + transactionAmountInCents,
  };
}

/// Reverses [computeBalanceAfterTransaction] for the same inputs (non-credit).
int computeBalanceAfterRemovingTransaction({
  required int accountBalanceInCents,
  required int transactionAmountInCents,
  required TransactionType transactionType,
  required PaymentMethod paymentMethod,
}) {
  if (paymentMethod == PaymentMethod.credit) {
    return accountBalanceInCents;
  }
  return switch (transactionType) {
    TransactionType.expense => accountBalanceInCents + transactionAmountInCents,
    TransactionType.income => accountBalanceInCents - transactionAmountInCents,
  };
}

/// Sum of account balances minus sum of [openInvoices] effective totals.
///
/// Callers choose which invoices to include (e.g. by due date in a month).
int computeTotalUserBalance({
  required Iterable<int> accountBalancesInCents,
  required Iterable<OpenInvoiceBalanceInput> openInvoices,
}) {
  final int accountsSum = accountBalancesInCents.fold(
    0,
    (int sum, int b) => sum + b,
  );
  final int invoicesSum = openInvoices.fold(
    0,
    (int sum, OpenInvoiceBalanceInput inv) => sum + inv.effectiveTotalInCents,
  );
  return accountsSum - invoicesSum;
}

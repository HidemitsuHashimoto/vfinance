import 'package:vfinance/domain/balance_period_rules.dart';
import 'package:vfinance/domain/balance_rules.dart';

/// Calendar month identifying an invoice cycle (year + month 1–12).
final class InvoiceCycleMonth {
  const InvoiceCycleMonth({required this.year, required this.month});

  final int year;
  final int month;

  @override
  bool operator ==(Object other) {
    return other is InvoiceCycleMonth &&
        other.year == year &&
        other.month == month;
  }

  @override
  int get hashCode => Object.hash(year, month);
}

/// Maps a purchase calendar date and [closingDay] to the invoice cycle month.
///
/// Rule from [domain.md]: if purchase day <= [closingDay] → current month’s
/// cycle; otherwise the next calendar month (year rolls when needed).
///
/// Uses [purchaseDate]’s `year`, `month`, and `day` as the user’s calendar
/// date (normalize to local date before calling when stored as UTC instant).
/// Inclusive local calendar bounds for purchase dates that bill in the
/// invoice cycle [cycleYear]/[cycleMonth] for [closingDay] (same rule as
/// [computeInvoiceCycleMonth]).
(DateTime startInclusive, DateTime endInclusive)
invoiceCyclePurchaseInclusiveBounds({
  required int cycleYear,
  required int cycleMonth,
  required int closingDay,
}) {
  if (closingDay < 1 || closingDay > 31) {
    throw ArgumentError.value(closingDay, 'closingDay', 'expected 1..31');
  }
  final DateTime endInclusive = invoiceDueDateForCycle(
    cycleYear: cycleYear,
    cycleMonth: cycleMonth,
    dueDay: closingDay,
  );
  final DateTime prevMonthStart = DateTime(cycleYear, cycleMonth - 1, 1);
  final int lastDayPrevMonth = DateTime(
    prevMonthStart.year,
    prevMonthStart.month + 1,
    0,
  ).day;
  final int rawStartDay = closingDay + 1;
  final DateTime startInclusive;
  if (rawStartDay <= lastDayPrevMonth) {
    startInclusive = DateTime(
      prevMonthStart.year,
      prevMonthStart.month,
      rawStartDay,
    );
  } else {
    startInclusive = DateTime(cycleYear, cycleMonth, 1);
  }
  return (startInclusive, endInclusive);
}

InvoiceCycleMonth computeInvoiceCycleMonth({
  required DateTime purchaseDate,
  required int closingDay,
}) {
  if (closingDay < 1 || closingDay > 31) {
    throw ArgumentError.value(closingDay, 'closingDay', 'expected 1..31');
  }
  if (purchaseDate.day <= closingDay) {
    return InvoiceCycleMonth(
      year: purchaseDate.year,
      month: purchaseDate.month,
    );
  }
  final DateTime nextMonth = DateTime(
    purchaseDate.year,
    purchaseDate.month + 1,
    1,
  );
  return InvoiceCycleMonth(year: nextMonth.year, month: nextMonth.month);
}

/// Sum of transaction amounts for one invoice, in centavos.
int computeInvoiceTotalInCents(Iterable<int> transactionAmountsInCents) {
  return transactionAmountsInCents.fold(0, (int sum, int cents) => sum + cents);
}

/// Display / balance total when [adjustedTotalInCents] overrides the sum.
int effectiveInvoiceTotalInCents({
  required int totalInCents,
  int? adjustedTotalInCents,
}) {
  return adjustedTotalInCents ?? totalInCents;
}

/// UI hint for list rows only (e.g. cartões / faturas). Does **not** drive
/// total balance math; [isPaid] is informational.
bool invoiceShowsAsOpenInList({required bool isPaid}) {
  return !isPaid;
}

/// Yields [OpenInvoiceBalanceInput] for every invoice (paid flag ignored).
///
/// Prefer `CreditCardBilling.openInvoiceBalanceInputsDueInLocalRange` on the
/// home dashboard so totals respect pay periods and due dates.
Iterable<OpenInvoiceBalanceInput> openInvoiceBalanceInputsForTotal({
  required Iterable<InvoiceBalanceDescriptor> invoices,
}) sync* {
  for (final InvoiceBalanceDescriptor i in invoices) {
    yield OpenInvoiceBalanceInput(
      totalInCents: i.totalInCents,
      adjustedTotalInCents: i.adjustedTotalInCents,
    );
  }
}

/// Invoice amounts and flags for filtering into [computeTotalUserBalance].
final class InvoiceBalanceDescriptor {
  const InvoiceBalanceDescriptor({
    required this.totalInCents,
    this.adjustedTotalInCents,
    required this.isPaid,
  });

  final int totalInCents;
  final int? adjustedTotalInCents;
  final bool isPaid;
}

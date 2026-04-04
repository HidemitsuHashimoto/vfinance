import 'package:vfinance/domain/finance_calendar_date.dart';
import 'package:vfinance/domain/transaction_enums.dart';

/// Transaction row for summarizing cashflow in a local date range.
final class TransactionTimelineRow {
  const TransactionTimelineRow({
    required this.amountInCents,
    required this.transactionTypeStorage,
    required this.paymentMethodStorage,
    required this.dateUtcMillis,
  });

  final int amountInCents;
  final String transactionTypeStorage;
  final String paymentMethodStorage;
  final int dateUtcMillis;
}

/// Due calendar date for an invoice cycle ([year]/[month]) using the card’s
/// [dueDay], clamped to the month’s length.
DateTime invoiceDueDateForCycle({
  required int cycleYear,
  required int cycleMonth,
  required int dueDay,
}) {
  final int lastDay = DateTime(cycleYear, cycleMonth + 1, 0).day;
  final int day = dueDay.clamp(1, lastDay);
  return DateTime(cycleYear, cycleMonth, day);
}

DateTime _dateOnlyLocal(DateTime dateTime) {
  return DateTime(dateTime.year, dateTime.month, dateTime.day);
}

bool _isDateOnlyInRange({
  required DateTime date,
  required DateTime rangeStartLocal,
  required DateTime rangeEndLocal,
}) {
  final DateTime d = _dateOnlyLocal(date);
  final DateTime start = _dateOnlyLocal(rangeStartLocal);
  final DateTime end = _dateOnlyLocal(rangeEndLocal);
  return !d.isBefore(start) && !d.isAfter(end);
}

/// Inclusive local calendar bounds for the month containing [anchorLocal].
(DateTime start, DateTime end) localMonthBounds(DateTime anchorLocal) {
  final DateTime start = DateTime(anchorLocal.year, anchorLocal.month, 1);
  final DateTime end = DateTime(anchorLocal.year, anchorLocal.month + 1, 0);
  return (start, end);
}

/// Calendar date of [anchorDay] (1–31) in [year]/[month], clamped to month
/// length (same rules as [invoiceDueDateForCycle]).
DateTime payCycleAnchorDateInMonth({
  required int year,
  required int month,
  required int anchorDay,
}) {
  return invoiceDueDateForCycle(
    cycleYear: year,
    cycleMonth: month,
    dueDay: anchorDay,
  );
}

/// Inclusive local date bounds for the current pay cycle: from the latest
/// anchor on or before [todayLocal] to the day before the next anchor.
///
/// [anchorDay] is the calendar day of month (1–31) when income is received.
(DateTime startInclusive, DateTime endInclusive)
payCycleLocalBoundsForAnchorDay({
  required DateTime todayLocal,
  required int anchorDay,
}) {
  final DateTime today = _dateOnlyLocal(todayLocal);
  final DateTime thisMonthAnchor = payCycleAnchorDateInMonth(
    year: today.year,
    month: today.month,
    anchorDay: anchorDay,
  );
  final DateTime cycleStart = !thisMonthAnchor.isAfter(today)
      ? thisMonthAnchor
      : payCycleAnchorDateInMonth(
          year: today.month == 1 ? today.year - 1 : today.year,
          month: today.month == 1 ? 12 : today.month - 1,
          anchorDay: anchorDay,
        );
  final DateTime nextMonth = DateTime(cycleStart.year, cycleStart.month + 1, 1);
  final DateTime nextAnchor = payCycleAnchorDateInMonth(
    year: nextMonth.year,
    month: nextMonth.month,
    anchorDay: anchorDay,
  );
  final DateTime endInclusive = _dateOnlyLocal(
    nextAnchor.subtract(const Duration(days: 1)),
  );
  return (cycleStart, endInclusive);
}

/// Sums income and immediate (non-credit) expenses whose **local** calendar
/// date lies in the range.
({int incomeCents, int immediateExpenseCents}) summarizeCashflowInLocalRange({
  required Iterable<TransactionTimelineRow> transactions,
  required DateTime rangeStartLocal,
  required DateTime rangeEndLocal,
}) {
  int incomeCents = 0;
  int immediateExpenseCents = 0;
  for (final TransactionTimelineRow t in transactions) {
    final DateTime localCivil = localCivilDateFromFinanceEpochMillis(
      t.dateUtcMillis,
    );
    if (!_isDateOnlyInRange(
      date: localCivil,
      rangeStartLocal: rangeStartLocal,
      rangeEndLocal: rangeEndLocal,
    )) {
      continue;
    }
    final TransactionType type = TransactionType.parseStorage(
      t.transactionTypeStorage,
    );
    final PaymentMethod method = PaymentMethod.parseStorage(
      t.paymentMethodStorage,
    );
    switch (type) {
      case TransactionType.income:
        incomeCents += t.amountInCents;
      case TransactionType.expense:
        if (method != PaymentMethod.credit) {
          immediateExpenseCents += t.amountInCents;
        }
    }
  }
  return (
    incomeCents: incomeCents,
    immediateExpenseCents: immediateExpenseCents,
  );
}

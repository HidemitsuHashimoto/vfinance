/// Splits [totalInCents] into [installmentCount] non-negative parts in
/// centavos.
///
/// **Product rule:** installments `0 .. count - 2` receive
/// `totalInCents ~/ installmentCount`; the **last** installment receives the
/// remainder so the sum always equals [totalInCents].
List<int> splitTotalInCentsAcrossInstallments({
  required int totalInCents,
  required int installmentCount,
}) {
  if (installmentCount < 1) {
    throw ArgumentError.value(
      installmentCount,
      'installmentCount',
      'expected >= 1',
    );
  }
  if (totalInCents < 0) {
    throw ArgumentError.value(totalInCents, 'totalInCents', 'expected >= 0');
  }
  if (installmentCount == 1) {
    return <int>[totalInCents];
  }
  final int baseSlice = totalInCents ~/ installmentCount;
  final int lastSlice = totalInCents - baseSlice * (installmentCount - 1);
  return <int>[
    for (int i = 0; i < installmentCount - 1; i++) baseSlice,
    lastSlice,
  ];
}

/// Returns [installmentCount] purchase dates starting at [firstPurchaseDate].
///
/// **Product rule:** installment `k` is dated `k` calendar months after the
/// first, keeping the same **day of month** when possible; when the target month
/// is shorter, the date is the **last valid day** of that month.
List<DateTime> computeInstallmentPurchaseDates({
  required DateTime firstPurchaseDate,
  required int installmentCount,
}) {
  if (installmentCount < 1) {
    throw ArgumentError.value(
      installmentCount,
      'installmentCount',
      'expected >= 1',
    );
  }
  return <DateTime>[
    for (int i = 0; i < installmentCount; i++)
      _addCalendarMonthsPreserveDayOfMonth(
        date: firstPurchaseDate,
        monthsToAdd: i,
      ),
  ];
}

DateTime _addCalendarMonthsPreserveDayOfMonth({
  required DateTime date,
  required int monthsToAdd,
}) {
  if (monthsToAdd < 0) {
    throw ArgumentError.value(monthsToAdd, 'monthsToAdd', 'expected >= 0');
  }
  final int year = date.year;
  final int month = date.month;
  final int day = date.day;
  final int totalMonths0Indexed = month - 1 + monthsToAdd;
  final int resultYear = year + totalMonths0Indexed ~/ 12;
  final int resultMonth = totalMonths0Indexed % 12 + 1;
  final int lastDayInTargetMonth = DateTime(resultYear, resultMonth + 1, 0).day;
  final int resultDay = day > lastDayInTargetMonth ? lastDayInTargetMonth : day;
  return DateTime(resultYear, resultMonth, resultDay);
}

/// One planned credit-card installment line (domain-only; persist as credit
/// rows sharing [installmentGroupId], e.g. `installmentId` in storage).
final class PlannedCreditInstallmentCharge {
  const PlannedCreditInstallmentCharge({
    required this.installmentGroupId,
    required this.installmentIndex,
    required this.amountInCents,
    required this.purchaseDate,
  });

  final int installmentGroupId;
  final int installmentIndex;
  final int amountInCents;
  final DateTime purchaseDate;
}

/// Builds [installmentCount] credit installment charges sharing
/// [installmentGroupId] (maps to `installmentId` in storage).
List<PlannedCreditInstallmentCharge> planCreditInstallmentCharges({
  required int installmentGroupId,
  required int totalAmountInCents,
  required int installmentCount,
  required DateTime firstPurchaseDate,
}) {
  final List<int> amounts = splitTotalInCentsAcrossInstallments(
    totalInCents: totalAmountInCents,
    installmentCount: installmentCount,
  );
  final List<DateTime> dates = computeInstallmentPurchaseDates(
    firstPurchaseDate: firstPurchaseDate,
    installmentCount: installmentCount,
  );
  return <PlannedCreditInstallmentCharge>[
    for (int i = 0; i < installmentCount; i++)
      PlannedCreditInstallmentCharge(
        installmentGroupId: installmentGroupId,
        installmentIndex: i,
        amountInCents: amounts[i],
        purchaseDate: dates[i],
      ),
  ];
}

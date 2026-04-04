/// Finance dates are stored as **epoch milliseconds** (universal instant).
///
/// The user picks a **local calendar day** in the UI; we persist the instant
/// returned by [financeEpochMillisFromLocalYmd] (local midnight for that day).
/// All business rules that depend on “which calendar day is this?” use
/// [localCivilDateFromFinanceEpochMillis] so they match what the user sees.
DateTime localCivilDateFromFinanceEpochMillis(int millisSinceEpoch) {
  final DateTime wall = DateTime.fromMillisecondsSinceEpoch(millisSinceEpoch);
  return DateTime(wall.year, wall.month, wall.day);
}

/// Epoch millis for local midnight on [year]/[month]/[day].
int financeEpochMillisFromLocalYmd(int year, int month, int day) {
  return DateTime(year, month, day).millisecondsSinceEpoch;
}

/// Whether [localCivilDate] (date-only semantics) lies in
/// [[rangeStartLocal], [rangeEndLocal]] inclusive.
bool isLocalCivilDateInInclusiveRange({
  required DateTime localCivilDate,
  required DateTime rangeStartLocal,
  required DateTime rangeEndLocal,
}) {
  final DateTime d = DateTime(
    localCivilDate.year,
    localCivilDate.month,
    localCivilDate.day,
  );
  final DateTime start = DateTime(
    rangeStartLocal.year,
    rangeStartLocal.month,
    rangeStartLocal.day,
  );
  final DateTime end = DateTime(
    rangeEndLocal.year,
    rangeEndLocal.month,
    rangeEndLocal.day,
  );
  return !d.isBefore(start) && !d.isAfter(end);
}

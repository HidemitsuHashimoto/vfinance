import 'package:vfinance/domain/money.dart';

/// Formats persisted centavos for UI (Brazilian Real).
String formatCents(int cents) => Money(cents).formatBrl();

/// Plain decimal string for money text fields (no currency prefix).
String formatCentsAsReaisInput(int cents) {
  return Money(cents).formatBrl().replaceFirst(RegExp(r'^R\$\s*'), '');
}

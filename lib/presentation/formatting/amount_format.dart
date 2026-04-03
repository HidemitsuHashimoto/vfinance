import 'package:vfinance/domain/money.dart';

/// Formats persisted centavos for UI (Brazilian Real).
String formatCents(int cents) => Money(cents).formatBrl();

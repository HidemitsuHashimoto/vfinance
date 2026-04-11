import 'dart:math' as math;

/// Monetary amount stored as an integer number of centavos.
///
/// Avoids floating point for business calculations, matching [domain.md].
final class Money {
  const Money(this.cents);

  final int cents;

  Money operator +(Money other) => Money(cents + other.cents);

  Money operator -(Money other) => Money(cents - other.cents);

  Money operator -() => Money(-cents);

  bool get isNegative => cents < 0;

  bool get isPositive => cents > 0;

  /// Displays value as Brazilian Real using comma as decimal separator.
  String formatBrl() {
    final int sign = cents < 0 ? -1 : 1;
    final int abs = cents.abs();
    final int whole = abs ~/ 100;
    final int frac = abs % 100;
    final String core = 'R\$ $whole,${frac.toString().padLeft(2, '0')}';
    return sign < 0 ? '-$core' : core;
  }

  /// Parses a user amount in reais.
  ///
  /// When the input has no comma or dot, it is treated as an integer number of
  /// centavos (e.g. `1050` → R\$ 10,50), matching common keypad-style entry.
  ///
  /// When a comma or dot is present, the value is parsed as reais with an
  /// optional fractional part. Truncates extra fraction digits toward zero like
  /// `(BigDecimal * 100).toLong()` in the domain reference.
  static Money parseReais(String raw) {
    final String trimmed = raw.trim();
    if (trimmed.isEmpty) {
      throw const FormatException('Empty money string');
    }
    final bool hasExplicitSeparator =
        trimmed.contains(',') || trimmed.contains('.');
    if (!hasExplicitSeparator) {
      final String unsignedDigits = trimmed.startsWith('-')
          ? trimmed.substring(1)
          : trimmed;
      if (unsignedDigits.isNotEmpty &&
          _digitsOnly.hasMatch(unsignedDigits)) {
        return Money(int.parse(trimmed));
      }
    }
    final String normalized = trimmed.replaceAll(',', '.');
    if (!_normalizedPattern.hasMatch(normalized)) {
      throw FormatException('Invalid money string', raw);
    }
    final bool isNegative = normalized.startsWith('-');
    final String unsigned = isNegative ? normalized.substring(1) : normalized;
    final List<String> parts = unsigned.split('.');
    final String wholePart = parts[0];
    if (wholePart.isEmpty || !_digitsOnly.hasMatch(wholePart)) {
      throw FormatException('Invalid money string', raw);
    }
    final int whole = int.parse(wholePart);
    final String fracPart = parts.length == 2 ? parts[1] : '';
    if (fracPart.isNotEmpty && !_digitsOnly.hasMatch(fracPart)) {
      throw FormatException('Invalid money string', raw);
    }
    final int sign = isNegative ? -1 : 1;
    final int centsFromWhole = whole * sign * 100;
    final int centsFromFrac = _fractionToCents(fracPart) * sign;
    return Money(centsFromWhole + centsFromFrac);
  }

  static final RegExp _normalizedPattern = RegExp(r'^-?\d+(\.\d+)?$');
  static final RegExp _digitsOnly = RegExp(r'^\d+$');

  static int _fractionToCents(String frac) {
    if (frac.isEmpty) {
      return 0;
    }
    final int s = frac.length;
    final int fracInt = int.parse(frac);
    if (s <= 2) {
      return fracInt * math.pow(10, 2 - s).toInt();
    }
    return fracInt ~/ math.pow(10, s - 2).toInt();
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:vfinance/domain/money.dart';

void main() {
  group('Money operators', () {
    test('plus adds two positive amounts in cents', () {
      const Money a = Money(1000);
      const Money b = Money(250);
      expect((a + b).cents, 1250);
    });

    test('minus subtracts amounts in cents', () {
      const Money a = Money(1000);
      const Money b = Money(250);
      expect((a - b).cents, 750);
    });

    test('unary minus negates cents', () {
      const Money a = Money(100);
      expect((-a).cents, -100);
    });

    test('isNegative and isPositive follow sign of cents', () {
      expect(const Money(-1).isNegative, isTrue);
      expect(const Money(0).isNegative, isFalse);
      expect(const Money(1).isPositive, isTrue);
      expect(const Money(0).isPositive, isFalse);
    });
  });

  group('Money.parseReais', () {
    test('parses comma decimal like domain example', () {
      expect(Money.parseReais('10,50').cents, 1050);
    });

    test('parses dot decimal', () {
      expect(Money.parseReais('0.99').cents, 99);
    });

    test('parses integer reais as centavos * 100', () {
      expect(Money.parseReais('10').cents, 1000);
    });

    test('truncates extra fractional digits like BigDecimal*100 toLong', () {
      expect(Money.parseReais('10.555').cents, 1055);
    });

    test('parses negative values', () {
      expect(Money.parseReais('-3,20').cents, -320);
    });

    test('throws on empty input', () {
      expect(() => Money.parseReais(''), throwsFormatException);
    });

    test('throws on invalid number', () {
      expect(() => Money.parseReais('abc'), throwsFormatException);
    });
  });

  group('Money.formatBrl', () {
    test('formats positive cents as R\$ with two decimals', () {
      expect(const Money(1050).formatBrl(), 'R\$ 10,50');
    });

    test('formats negative cents with minus before currency', () {
      expect(const Money(-99).formatBrl(), '-R\$ 0,99');
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:vfinance/domain/transaction_enums.dart';

void main() {
  group('TransactionType storage round-trip', () {
    test('values match domain contract', () {
      expect(TransactionType.expense.storageName, 'EXPENSE');
      expect(TransactionType.income.storageName, 'INCOME');
    });

    test('parse accepts storage names', () {
      expect(TransactionType.parseStorage('EXPENSE'), TransactionType.expense);
      expect(TransactionType.parseStorage('INCOME'), TransactionType.income);
    });

    test('parse throws on unknown value', () {
      expect(
        () => TransactionType.parseStorage('OTHER'),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('PaymentMethod storage round-trip', () {
    test('values match domain contract', () {
      expect(PaymentMethod.pix.storageName, 'PIX');
      expect(PaymentMethod.debit.storageName, 'DEBIT');
      expect(PaymentMethod.credit.storageName, 'CREDIT');
      expect(PaymentMethod.boleto.storageName, 'BOLETO');
    });

    test('parse accepts storage names', () {
      expect(PaymentMethod.parseStorage('PIX'), PaymentMethod.pix);
      expect(PaymentMethod.parseStorage('CREDIT'), PaymentMethod.credit);
    });

    test('parse throws on unknown value', () {
      expect(
        () => PaymentMethod.parseStorage('CASH'),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}

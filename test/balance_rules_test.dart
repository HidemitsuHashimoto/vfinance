import 'package:flutter_test/flutter_test.dart';
import 'package:vfinance/domain/balance_rules.dart';
import 'package:vfinance/domain/transaction_enums.dart';

void main() {
  group('computeBalanceAfterTransaction', () {
    test('expense on debit reduces balance', () {
      expect(
        computeBalanceAfterTransaction(
          accountBalanceInCents: 10_000,
          transactionAmountInCents: 3_500,
          transactionType: TransactionType.expense,
          paymentMethod: PaymentMethod.debit,
        ),
        6_500,
      );
    });

    test('income on pix increases balance', () {
      expect(
        computeBalanceAfterTransaction(
          accountBalanceInCents: 1_000,
          transactionAmountInCents: 250,
          transactionType: TransactionType.income,
          paymentMethod: PaymentMethod.pix,
        ),
        1_250,
      );
    });

    test('expense on credit leaves balance unchanged', () {
      expect(
        computeBalanceAfterTransaction(
          accountBalanceInCents: 5_000,
          transactionAmountInCents: 9_999,
          transactionType: TransactionType.expense,
          paymentMethod: PaymentMethod.credit,
        ),
        5_000,
      );
    });

    test('income on credit leaves balance unchanged', () {
      expect(
        computeBalanceAfterTransaction(
          accountBalanceInCents: 200,
          transactionAmountInCents: 100,
          transactionType: TransactionType.income,
          paymentMethod: PaymentMethod.credit,
        ),
        200,
      );
    });

    test('boleto behaves like immediate account methods', () {
      expect(
        computeBalanceAfterTransaction(
          accountBalanceInCents: 800,
          transactionAmountInCents: 100,
          transactionType: TransactionType.expense,
          paymentMethod: PaymentMethod.boleto,
        ),
        700,
      );
    });
  });

  group('computeTotalUserBalance', () {
    test('sums accounts only when there are no open invoices', () {
      expect(
        computeTotalUserBalance(
          accountBalancesInCents: const <int>[3_000, 7_000],
          openInvoices: const <OpenInvoiceBalanceInput>[],
        ),
        10_000,
      );
    });

    test('subtracts open invoice totals from account sum', () {
      expect(
        computeTotalUserBalance(
          accountBalancesInCents: const <int>[10_000, 5_000],
          openInvoices: const <OpenInvoiceBalanceInput>[
            OpenInvoiceBalanceInput(totalInCents: 2_000),
            OpenInvoiceBalanceInput(totalInCents: 500),
          ],
        ),
        12_500,
      );
    });

    test('uses adjusted total when present', () {
      expect(
        computeTotalUserBalance(
          accountBalancesInCents: const <int>[20_000],
          openInvoices: const <OpenInvoiceBalanceInput>[
            OpenInvoiceBalanceInput(
              totalInCents: 5_000,
              adjustedTotalInCents: 4_200,
            ),
          ],
        ),
        15_800,
      );
    });

    test('mixed adjusted and raw totals', () {
      expect(
        computeTotalUserBalance(
          accountBalancesInCents: const <int>[8_000, 2_000],
          openInvoices: const <OpenInvoiceBalanceInput>[
            OpenInvoiceBalanceInput(
              totalInCents: 1_000,
              adjustedTotalInCents: 1_500,
            ),
            OpenInvoiceBalanceInput(totalInCents: 300),
          ],
        ),
        8_200,
      );
    });
  });
}

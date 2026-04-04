import 'package:flutter_test/flutter_test.dart';
import 'package:vfinance/domain/balance_rules.dart';
import 'package:vfinance/domain/credit_card_billing.dart';
import 'package:vfinance/domain/finance_calendar_date.dart';
import 'package:vfinance/domain/invoice_rules.dart';
import 'package:vfinance/domain/transaction_enums.dart';

void main() {
  group('CreditCardBilling.openInvoiceBalanceInputsDueInLocalRange', () {
    test('includes cycle when due falls inside range', () {
      final int d4 = financeEpochMillisFromLocalYmd(2026, 4, 4);
      final int d5 = financeEpochMillisFromLocalYmd(2026, 4, 5);
      final List<OpenInvoiceBalanceInput> inputs =
          CreditCardBilling.openInvoiceBalanceInputsDueInLocalRange(
            cards: const <CreditCardBillingCard>[
              CreditCardBillingCard(id: 1, closingDay: 15, dueDay: 19),
            ],
            transactions: <CreditCardBillingTransaction>[
              CreditCardBillingTransaction(
                amountInCents: 2_000,
                transactionTypeStorage: TransactionType.expense.storageName,
                paymentMethodStorage: PaymentMethod.credit.storageName,
                dateUtcMillis: d4,
                cardId: 1,
              ),
              CreditCardBillingTransaction(
                amountInCents: 500,
                transactionTypeStorage: TransactionType.expense.storageName,
                paymentMethodStorage: PaymentMethod.credit.storageName,
                dateUtcMillis: d5,
                cardId: 1,
              ),
            ],
            invoices: const <CreditCardBillingInvoice>[],
            rangeStartLocal: DateTime(2026, 3, 20),
            rangeEndLocal: DateTime(2026, 4, 19),
          ).toList();
      expect(inputs, hasLength(1));
      expect(inputs.single.effectiveTotalInCents, 2_500);
    });

    test('omits cycle when due is outside range', () {
      final int millis = financeEpochMillisFromLocalYmd(2026, 4, 20);
      final List<OpenInvoiceBalanceInput> inputs =
          CreditCardBilling.openInvoiceBalanceInputsDueInLocalRange(
            cards: const <CreditCardBillingCard>[
              CreditCardBillingCard(id: 1, closingDay: 15, dueDay: 19),
            ],
            transactions: <CreditCardBillingTransaction>[
              CreditCardBillingTransaction(
                amountInCents: 1_000,
                transactionTypeStorage: TransactionType.expense.storageName,
                paymentMethodStorage: PaymentMethod.credit.storageName,
                dateUtcMillis: millis,
                cardId: 1,
              ),
            ],
            invoices: const <CreditCardBillingInvoice>[],
            rangeStartLocal: DateTime(2026, 4, 1),
            rangeEndLocal: DateTime(2026, 4, 30),
          ).toList();
      expect(inputs, isEmpty);
    });

    test('respects adjusted total for balance', () {
      final int millis = financeEpochMillisFromLocalYmd(2026, 4, 10);
      final List<OpenInvoiceBalanceInput> inputs =
          CreditCardBilling.openInvoiceBalanceInputsDueInLocalRange(
            cards: const <CreditCardBillingCard>[
              CreditCardBillingCard(id: 1, closingDay: 15, dueDay: 10),
            ],
            transactions: <CreditCardBillingTransaction>[
              CreditCardBillingTransaction(
                amountInCents: 1_000,
                transactionTypeStorage: TransactionType.expense.storageName,
                paymentMethodStorage: PaymentMethod.credit.storageName,
                dateUtcMillis: millis,
                cardId: 1,
              ),
            ],
            invoices: const <CreditCardBillingInvoice>[
              CreditCardBillingInvoice(
                cardId: 1,
                year: 2026,
                month: 4,
                adjustedTotalInCents: 800,
              ),
            ],
            rangeStartLocal: DateTime(2026, 4, 1),
            rangeEndLocal: DateTime(2026, 4, 30),
          ).toList();
      expect(inputs.single.effectiveTotalInCents, 800);
    });
  });

  group('computeInvoiceCycleMonth with local civil date', () {
    test('5 April with closing 15 stays in April cycle', () {
      final int millis = financeEpochMillisFromLocalYmd(2026, 4, 5);
      final DateTime civil = localCivilDateFromFinanceEpochMillis(millis);
      final InvoiceCycleMonth cycle = computeInvoiceCycleMonth(
        purchaseDate: civil,
        closingDay: 15,
      );
      expect(cycle.year, 2026);
      expect(cycle.month, 4);
    });
  });
}

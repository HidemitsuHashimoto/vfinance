import 'package:flutter_test/flutter_test.dart';
import 'package:vfinance/domain/balance_period_rules.dart';
import 'package:vfinance/domain/balance_rules.dart';
import 'package:vfinance/domain/transaction_enums.dart';

void main() {
  group('invoiceDueDateForCycle', () {
    test('clamps due day to month length', () {
      expect(
        invoiceDueDateForCycle(cycleYear: 2026, cycleMonth: 2, dueDay: 31),
        DateTime(2026, 2, 28),
      );
    });
  });

  group('payCycleLocalBoundsForAnchorDay', () {
    test('before pay day this month uses previous month anchor', () {
      final (DateTime start, DateTime end) = payCycleLocalBoundsForAnchorDay(
        todayLocal: DateTime(2026, 4, 4),
        anchorDay: 20,
      );
      expect(start, DateTime(2026, 3, 20));
      expect(end, DateTime(2026, 4, 19));
    });

    test('on or after pay day this month uses this month anchor', () {
      final (DateTime start, DateTime end) = payCycleLocalBoundsForAnchorDay(
        todayLocal: DateTime(2026, 4, 21),
        anchorDay: 20,
      );
      expect(start, DateTime(2026, 4, 20));
      expect(end, DateTime(2026, 5, 19));
    });

    test('anchor on day 5 before fifth uses previous cycle', () {
      final (DateTime start, DateTime end) = payCycleLocalBoundsForAnchorDay(
        todayLocal: DateTime(2026, 3, 3),
        anchorDay: 5,
      );
      expect(start, DateTime(2026, 2, 5));
      expect(end, DateTime(2026, 3, 4));
    });

    test('anchor 31 in February clamps and next month resolves', () {
      final (DateTime start, DateTime end) = payCycleLocalBoundsForAnchorDay(
        todayLocal: DateTime(2026, 3, 10),
        anchorDay: 31,
      );
      expect(start, DateTime(2026, 2, 28));
      expect(end, DateTime(2026, 3, 30));
    });

    test('year rollover when today is January before anchor', () {
      final (DateTime start, DateTime end) = payCycleLocalBoundsForAnchorDay(
        todayLocal: DateTime(2026, 1, 10),
        anchorDay: 20,
      );
      expect(start, DateTime(2025, 12, 20));
      expect(end, DateTime(2026, 1, 19));
    });
  });

  group('invoiceBalanceInputsDueInLocalRange', () {
    test('includes invoice when due falls inside range', () {
      final List<OpenInvoiceBalanceInput> inputs =
          invoiceBalanceInputsDueInLocalRange(
            invoices: const <InvoiceCycleSnapshot>[
              InvoiceCycleSnapshot(
                cardId: 1,
                year: 2026,
                month: 4,
                totalInCents: 1_000,
              ),
            ],
            cardById: const <int, CardDueDescriptor>{
              1: CardDueDescriptor(id: 1, dueDay: 10),
            },
            rangeStartLocal: DateTime(2026, 4, 1),
            rangeEndLocal: DateTime(2026, 4, 30),
          ).toList();
      expect(inputs.length, 1);
      expect(inputs.single.effectiveTotalInCents, 1_000);
    });

    test('omits invoice when due is outside range', () {
      final List<OpenInvoiceBalanceInput> inputs =
          invoiceBalanceInputsDueInLocalRange(
            invoices: const <InvoiceCycleSnapshot>[
              InvoiceCycleSnapshot(
                cardId: 1,
                year: 2026,
                month: 5,
                totalInCents: 1_000,
              ),
            ],
            cardById: const <int, CardDueDescriptor>{
              1: CardDueDescriptor(id: 1, dueDay: 10),
            },
            rangeStartLocal: DateTime(2026, 4, 1),
            rangeEndLocal: DateTime(2026, 4, 30),
          ).toList();
      expect(inputs, isEmpty);
    });
  });

  group('summarizeCashflowInLocalRange', () {
    test('sums income and non-credit expenses in local range', () {
      final int millis = DateTime.utc(
        2026,
        4,
        15,
        15,
        0,
        0,
      ).millisecondsSinceEpoch;
      final DateTime local = DateTime.fromMillisecondsSinceEpoch(
        millis,
        isUtc: true,
      ).toLocal();
      final DateTime rangeStart = DateTime(local.year, local.month, 1);
      final DateTime rangeEnd = DateTime(local.year, local.month + 1, 0);
      final ({int incomeCents, int immediateExpenseCents}) r =
          summarizeCashflowInLocalRange(
            transactions: <TransactionTimelineRow>[
              TransactionTimelineRow(
                amountInCents: 5_000,
                transactionTypeStorage: TransactionType.income.storageName,
                paymentMethodStorage: PaymentMethod.pix.storageName,
                dateUtcMillis: millis,
              ),
              TransactionTimelineRow(
                amountInCents: 1_000,
                transactionTypeStorage: TransactionType.expense.storageName,
                paymentMethodStorage: PaymentMethod.debit.storageName,
                dateUtcMillis: millis,
              ),
              TransactionTimelineRow(
                amountInCents: 3_000,
                transactionTypeStorage: TransactionType.expense.storageName,
                paymentMethodStorage: PaymentMethod.credit.storageName,
                dateUtcMillis: millis,
              ),
            ],
            rangeStartLocal: rangeStart,
            rangeEndLocal: rangeEnd,
          );
      expect(r.incomeCents, 5_000);
      expect(r.immediateExpenseCents, 1_000);
    });
  });
}

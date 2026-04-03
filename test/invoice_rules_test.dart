import 'package:flutter_test/flutter_test.dart';
import 'package:vfinance/domain/balance_rules.dart';
import 'package:vfinance/domain/invoice_rules.dart';

void main() {
  group('computeInvoiceCycleMonth', () {
    test('purchase on or before closingDay stays in current month', () {
      expect(
        computeInvoiceCycleMonth(
          purchaseDate: DateTime(2024, 3, 10),
          closingDay: 15,
        ),
        const InvoiceCycleMonth(year: 2024, month: 3),
      );
      expect(
        computeInvoiceCycleMonth(
          purchaseDate: DateTime(2024, 3, 15),
          closingDay: 15,
        ),
        const InvoiceCycleMonth(year: 2024, month: 3),
      );
    });

    test('purchase after closingDay moves to next month', () {
      expect(
        computeInvoiceCycleMonth(
          purchaseDate: DateTime(2024, 3, 20),
          closingDay: 15,
        ),
        const InvoiceCycleMonth(year: 2024, month: 4),
      );
    });

    test('year rolls from December to January', () {
      expect(
        computeInvoiceCycleMonth(
          purchaseDate: DateTime(2024, 12, 25),
          closingDay: 10,
        ),
        const InvoiceCycleMonth(year: 2025, month: 1),
      );
    });

    test('same calendar month edge with late closingDay', () {
      expect(
        computeInvoiceCycleMonth(
          purchaseDate: DateTime(2024, 1, 31),
          closingDay: 31,
        ),
        const InvoiceCycleMonth(year: 2024, month: 1),
      );
    });

    test('rejects closingDay outside 1..31', () {
      expect(
        () => computeInvoiceCycleMonth(
          purchaseDate: DateTime(2024, 5, 1),
          closingDay: 0,
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => computeInvoiceCycleMonth(
          purchaseDate: DateTime(2024, 5, 1),
          closingDay: 32,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('computeInvoiceTotalInCents', () {
    test('sums expense amounts for the invoice', () {
      expect(computeInvoiceTotalInCents(const <int>[1_000, 250, 50]), 1_300);
    });

    test('empty list is zero', () {
      expect(computeInvoiceTotalInCents(const <int>[]), 0);
    });
  });

  group('effectiveInvoiceTotalInCents', () {
    test('uses adjusted when present', () {
      expect(
        effectiveInvoiceTotalInCents(
          totalInCents: 5_000,
          adjustedTotalInCents: 4_200,
        ),
        4_200,
      );
    });

    test('falls back to summed total', () {
      expect(effectiveInvoiceTotalInCents(totalInCents: 3_000), 3_000);
    });
  });

  group('invoiceAffectsTotalUserBalance', () {
    test('unpaid affects balance', () {
      expect(invoiceAffectsTotalUserBalance(isPaid: false), isTrue);
    });

    test('paid does not affect balance', () {
      expect(invoiceAffectsTotalUserBalance(isPaid: true), isFalse);
    });
  });

  group('openInvoiceBalanceInputsForTotal + computeTotalUserBalance', () {
    test('only unpaid invoices reduce total; adjusted is respected', () {
      final List<InvoiceBalanceDescriptor> descriptors =
          <InvoiceBalanceDescriptor>[
            const InvoiceBalanceDescriptor(totalInCents: 2_000, isPaid: false),
            const InvoiceBalanceDescriptor(
              totalInCents: 5_000,
              adjustedTotalInCents: 4_200,
              isPaid: false,
            ),
            const InvoiceBalanceDescriptor(totalInCents: 9_000, isPaid: true),
          ];
      expect(
        computeTotalUserBalance(
          accountBalancesInCents: const <int>[30_000],
          openInvoices: openInvoiceBalanceInputsForTotal(invoices: descriptors),
        ),
        30_000 - 2_000 - 4_200,
      );
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:vfinance/domain/installment_rules.dart';
import 'package:vfinance/domain/invoice_rules.dart';

void main() {
  group('splitTotalInCentsAcrossInstallments', () {
    /// Product rule: the first [count − 1] installments share
    /// `total ~/ count` centavos; the **last** installment absorbs the
    /// remainder so the sum always equals [totalInCents].
    test('distributes remainder into last installment (documented rule)', () {
      expect(
        splitTotalInCentsAcrossInstallments(
          totalInCents: 100,
          installmentCount: 3,
        ),
        const <int>[33, 33, 34],
      );
      expect(
        splitTotalInCentsAcrossInstallments(
          totalInCents: 101,
          installmentCount: 3,
        ),
        const <int>[33, 33, 35],
      );
    });

    test('sum always equals total; count matches; none negative', () {
      final List<int> parts = splitTotalInCentsAcrossInstallments(
        totalInCents: 9_999,
        installmentCount: 7,
      );
      expect(parts.length, 7);
      expect(parts.fold<int>(0, (int s, int p) => s + p), 9_999);
      expect(parts.every((int p) => p >= 0), isTrue);
    });

    test('single installment returns full amount', () {
      expect(
        splitTotalInCentsAcrossInstallments(
          totalInCents: 4_200,
          installmentCount: 1,
        ),
        const <int>[4_200],
      );
    });

    test('rejects non-positive installment count', () {
      expect(
        () => splitTotalInCentsAcrossInstallments(
          totalInCents: 100,
          installmentCount: 0,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects negative total', () {
      expect(
        () => splitTotalInCentsAcrossInstallments(
          totalInCents: -1,
          installmentCount: 2,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('computeInstallmentPurchaseDates', () {
    /// Product rule: each installment is dated at the same calendar day as
    /// the first, advancing one calendar month per index; when a month has
    /// fewer days, use that month’s **last valid day** (e.g. Jan 31 → Feb 28).
    test(
      'clamps to last day when month is shorter (Jan 31 → Feb 28, 2023)',
      () {
        final DateTime first = DateTime(2023, 1, 31);
        final List<DateTime> dates = computeInstallmentPurchaseDates(
          firstPurchaseDate: first,
          installmentCount: 2,
        );
        expect(dates[0], DateTime(2023, 1, 31));
        expect(dates[1], DateTime(2023, 2, 28));
      },
    );

    test('leap year: Jan 31 + 1 month is Feb 29', () {
      final List<DateTime> dates = computeInstallmentPurchaseDates(
        firstPurchaseDate: DateTime(2024, 1, 31),
        installmentCount: 2,
      );
      expect(dates[1], DateTime(2024, 2, 29));
    });

    test('preserves day when month length allows', () {
      final List<DateTime> dates = computeInstallmentPurchaseDates(
        firstPurchaseDate: DateTime(2024, 3, 15),
        installmentCount: 4,
      );
      expect(dates, <DateTime>[
        DateTime(2024, 3, 15),
        DateTime(2024, 4, 15),
        DateTime(2024, 5, 15),
        DateTime(2024, 6, 15),
      ]);
    });

    test('rejects non-positive installment count', () {
      expect(
        () => computeInstallmentPurchaseDates(
          firstPurchaseDate: DateTime(2024, 1, 1),
          installmentCount: 0,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('planCreditInstallmentCharges', () {
    test('each charge shares installmentGroupId; amounts and dates align', () {
      const int groupId = 42;
      final List<PlannedCreditInstallmentCharge> plan =
          planCreditInstallmentCharges(
            installmentGroupId: groupId,
            totalAmountInCents: 100,
            installmentCount: 3,
            firstPurchaseDate: DateTime(2024, 3, 10),
          );
      expect(plan.length, 3);
      expect(
        plan.every((PlannedCreditInstallmentCharge c) {
          return c.installmentGroupId == groupId;
        }),
        isTrue,
      );
      expect(
        plan.map((PlannedCreditInstallmentCharge c) => c.amountInCents),
        const <int>[33, 33, 34],
      );
      expect(
        plan.map((PlannedCreditInstallmentCharge c) => c.installmentIndex),
        const <int>[0, 1, 2],
      );
      expect(
        plan.map((PlannedCreditInstallmentCharge c) => c.purchaseDate),
        computeInstallmentPurchaseDates(
          firstPurchaseDate: DateTime(2024, 3, 10),
          installmentCount: 3,
        ),
      );
    });

    test('first charge invoice cycle matches computeInvoiceCycleMonth '
        '(orchestration)', () {
      const int closingDay = 15;
      final List<PlannedCreditInstallmentCharge> plan =
          planCreditInstallmentCharges(
            installmentGroupId: 1,
            installmentCount: 3,
            totalAmountInCents: 300,
            firstPurchaseDate: DateTime(2024, 3, 20),
          );
      final PlannedCreditInstallmentCharge first = plan.first;
      expect(
        computeInvoiceCycleMonth(
          purchaseDate: first.purchaseDate,
          closingDay: closingDay,
        ),
        computeInvoiceCycleMonth(
          purchaseDate: DateTime(2024, 3, 20),
          closingDay: closingDay,
        ),
      );
      expect(
        computeInvoiceCycleMonth(
          purchaseDate: first.purchaseDate,
          closingDay: closingDay,
        ),
        const InvoiceCycleMonth(year: 2024, month: 4),
      );
    });
  });
}

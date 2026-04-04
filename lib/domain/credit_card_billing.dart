import 'package:vfinance/domain/balance_period_rules.dart';
import 'package:vfinance/domain/balance_rules.dart';
import 'package:vfinance/domain/finance_calendar_date.dart';
import 'package:vfinance/domain/invoice_rules.dart';
import 'package:vfinance/domain/transaction_enums.dart';

/// Card fields needed for billing cycles and due dates.
final class CreditCardBillingCard {
  const CreditCardBillingCard({
    required this.id,
    required this.closingDay,
    required this.dueDay,
  });

  final int id;
  final int closingDay;
  final int dueDay;
}

/// Minimal transaction row for aggregating credit-card spend by cycle.
final class CreditCardBillingTransaction {
  const CreditCardBillingTransaction({
    required this.amountInCents,
    required this.transactionTypeStorage,
    required this.paymentMethodStorage,
    required this.dateUtcMillis,
    this.cardId,
  });

  final int amountInCents;
  final String transactionTypeStorage;
  final String paymentMethodStorage;
  final int dateUtcMillis;
  final int? cardId;
}

/// Invoice metadata: [adjustedTotalInCents] overrides the computed total for
/// balance math ([OpenInvoiceBalanceInput.effectiveTotalInCents]).
final class CreditCardBillingInvoice {
  const CreditCardBillingInvoice({
    required this.cardId,
    required this.year,
    required this.month,
    this.adjustedTotalInCents,
  });

  final int cardId;
  final int year;
  final int month;
  final int? adjustedTotalInCents;
}

/// Credit-card business rules: cycle assignment, due dates, and which invoice
/// amounts count toward [computeTotalUserBalance] for a pay period.
final class CreditCardBilling {
  CreditCardBilling._();

  static String _cycleKey(int cardId, int year, int month) =>
      '$cardId|$year|$month';

  /// Sums credit **expense** amounts per (card, invoice cycle month).
  static Map<String, int> aggregateCreditExpenseTotalsByCycle({
    required Iterable<CreditCardBillingCard> cards,
    required Iterable<CreditCardBillingTransaction> transactions,
  }) {
    final Map<int, CreditCardBillingCard> cardById =
        <int, CreditCardBillingCard>{
          for (final CreditCardBillingCard c in cards) c.id: c,
        };
    final Map<String, int> sums = <String, int>{};
    for (final CreditCardBillingTransaction t in transactions) {
      if (t.cardId == null) {
        continue;
      }
      if (t.transactionTypeStorage != TransactionType.expense.storageName) {
        continue;
      }
      if (t.paymentMethodStorage != PaymentMethod.credit.storageName) {
        continue;
      }
      final CreditCardBillingCard? card = cardById[t.cardId!];
      if (card == null) {
        continue;
      }
      final DateTime civil = localCivilDateFromFinanceEpochMillis(
        t.dateUtcMillis,
      );
      final InvoiceCycleMonth cycle = computeInvoiceCycleMonth(
        purchaseDate: civil,
        closingDay: card.closingDay,
      );
      final String key = _cycleKey(t.cardId!, cycle.year, cycle.month);
      sums[key] = (sums[key] ?? 0) + t.amountInCents;
    }
    return sums;
  }

  /// Yields [OpenInvoiceBalanceInput] for every (card, cycle) whose **due date**
  /// falls in [[rangeStartLocal], [rangeEndLocal]] (local date-only).
  ///
  /// [totalInCents] comes from [aggregateCreditExpenseTotalsByCycle];
  /// [adjustedTotalInCents] comes from [invoices] when present for that cycle.
  static Iterable<OpenInvoiceBalanceInput>
  openInvoiceBalanceInputsDueInLocalRange({
    required Iterable<CreditCardBillingCard> cards,
    required Iterable<CreditCardBillingTransaction> transactions,
    required Iterable<CreditCardBillingInvoice> invoices,
    required DateTime rangeStartLocal,
    required DateTime rangeEndLocal,
  }) sync* {
    final Map<String, int> sums = aggregateCreditExpenseTotalsByCycle(
      cards: cards,
      transactions: transactions,
    );
    final Map<String, CreditCardBillingInvoice> invByKey =
        <String, CreditCardBillingInvoice>{};
    for (final CreditCardBillingInvoice inv in invoices) {
      invByKey[_cycleKey(inv.cardId, inv.year, inv.month)] = inv;
    }
    final Set<String> allKeys = <String>{...sums.keys, ...invByKey.keys};
    final Map<int, CreditCardBillingCard> cardById =
        <int, CreditCardBillingCard>{
          for (final CreditCardBillingCard c in cards) c.id: c,
        };
    for (final String key in allKeys) {
      final List<String> parts = key.split('|');
      if (parts.length != 3) {
        continue;
      }
      final int? cardId = int.tryParse(parts[0]);
      final int? year = int.tryParse(parts[1]);
      final int? month = int.tryParse(parts[2]);
      if (cardId == null || year == null || month == null) {
        continue;
      }
      final CreditCardBillingCard? card = cardById[cardId];
      if (card == null) {
        continue;
      }
      final DateTime due = invoiceDueDateForCycle(
        cycleYear: year,
        cycleMonth: month,
        dueDay: card.dueDay,
      );
      if (!isLocalCivilDateInInclusiveRange(
        localCivilDate: due,
        rangeStartLocal: rangeStartLocal,
        rangeEndLocal: rangeEndLocal,
      )) {
        continue;
      }
      final int total = sums[key] ?? 0;
      final int? adj = invByKey[key]?.adjustedTotalInCents;
      if (total == 0 && adj == null) {
        continue;
      }
      yield OpenInvoiceBalanceInput(
        totalInCents: total,
        adjustedTotalInCents: adj,
      );
    }
  }
}

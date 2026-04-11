import 'package:flutter_test/flutter_test.dart';
import 'package:vfinance/data/local/app_database.dart';
import 'package:vfinance/data/local/finance_local_repository.dart';
import 'package:vfinance/domain/installment_rules.dart';
import 'package:vfinance/domain/transaction_enums.dart';

void main() {
  test(
    'insertCreditCardInstallmentExpensePlan splits total and links rows',
    () async {
      final AppDatabase db = AppDatabase.memory();
      addTearDown(db.close);
      final FinanceLocalRepository repo = FinanceLocalRepository(db);
      final int cardId = await repo.insertCreditCard(
        name: 'Inter',
        limitInCents: 1_000_000_00,
        closingDay: 10,
        dueDay: 17,
      );
      const int totalCents = 43_585;
      const int count = 3;
      final DateTime first = DateTime(2026, 4, 11);
      final List<int> expectedAmounts = splitTotalInCentsAcrossInstallments(
        totalInCents: totalCents,
        installmentCount: count,
      );
      final List<DateTime> expectedDates = computeInstallmentPurchaseDates(
        firstPurchaseDate: first,
        installmentCount: count,
      );
      final List<String> descriptions = List<String>.generate(
        count,
        (int i) => 'Desc · ${i + 1}/$count',
      );
      final List<int> ids = await repo.insertCreditCardInstallmentExpensePlan(
        totalAmountInCents: totalCents,
        installmentCount: count,
        category: 'PJ',
        rowDescriptions: descriptions,
        firstPurchaseDate: first,
        cardId: cardId,
      );
      expect(ids.length, count);
      final int groupId = ids.first;
      expect(ids.every((int id) => id > 0), isTrue);
      final List<FinanceTransaction> rows = await db
          .select(db.financeTransactions)
          .get();
      expect(rows.length, count);
      rows.sort((FinanceTransaction a, FinanceTransaction b) {
        return a.dateUtcMillis.compareTo(b.dateUtcMillis);
      });
      for (int i = 0; i < count; i++) {
        final FinanceTransaction t = rows[i];
        expect(t.amountInCents, expectedAmounts[i]);
        expect(t.dateUtcMillis, expectedDates[i].millisecondsSinceEpoch);
        expect(t.installmentId, groupId);
        expect(t.cardId, cardId);
        expect(t.paymentMethod, PaymentMethod.credit.storageName);
        expect(t.transactionType, TransactionType.expense.storageName);
        expect(t.description, descriptions[i]);
      }
    },
  );
}

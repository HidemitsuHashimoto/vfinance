import 'package:flutter_test/flutter_test.dart';
import 'package:vfinance/data/local/app_database.dart';
import 'package:vfinance/data/local/finance_local_repository.dart';
import 'package:vfinance/domain/transaction_enums.dart';

void main() {
  test('debit expense decreases persisted account balance', () async {
    final AppDatabase db = AppDatabase.memory();
    addTearDown(db.close);
    final FinanceLocalRepository repo = FinanceLocalRepository(db);
    final int accountId = await repo.insertAccount(
      name: 'Conta',
      type: 'checking',
      balanceInCents: 5_000,
    );
    await repo.insertFinanceTransaction(
      amountInCents: 1_200,
      transactionType: TransactionType.expense,
      category: 'food',
      description: 'lunch',
      dateUtc: DateTime.utc(2026, 4, 1),
      paymentMethod: PaymentMethod.debit,
      accountId: accountId,
    );
    final row = await repo.getAccountById(accountId);
    expect(row, isNotNull);
    expect(row!.balanceInCents, 3_800);
  });

  test('credit expense does not change account balance', () async {
    final AppDatabase db = AppDatabase.memory();
    addTearDown(db.close);
    final FinanceLocalRepository repo = FinanceLocalRepository(db);
    final int accountId = await repo.insertAccount(
      name: 'Conta',
      type: 'checking',
      balanceInCents: 2_000,
    );
    await repo.insertFinanceTransaction(
      amountInCents: 500,
      transactionType: TransactionType.expense,
      category: 'shop',
      description: 'card',
      dateUtc: DateTime.utc(2026, 4, 2),
      paymentMethod: PaymentMethod.credit,
      accountId: accountId,
    );
    final row = await repo.getAccountById(accountId);
    expect(row, isNotNull);
    expect(row!.balanceInCents, 2_000);
  });

  test(
    'persists credit card and invoice with optional adjusted total',
    () async {
      final AppDatabase db = AppDatabase.memory();
      addTearDown(db.close);
      final FinanceLocalRepository repo = FinanceLocalRepository(db);
      final int cardId = await repo.insertCreditCard(
        name: 'Visa',
        limitInCents: 5_000_000,
        closingDay: 10,
        dueDay: 17,
      );
      final int invoiceId = await repo.insertInvoice(
        cardId: cardId,
        month: 4,
        year: 2026,
        totalInCents: 3_500,
        adjustedTotalInCents: 3_000,
        isClosed: true,
        isPaid: false,
      );
      final Invoice? row = await repo.getInvoiceById(invoiceId);
      expect(row, isNotNull);
      expect(row!.cardId, cardId);
      expect(row.month, 4);
      expect(row.year, 2026);
      expect(row.totalInCents, 3_500);
      expect(row.adjustedTotalInCents, 3_000);
      expect(row.isClosed, isTrue);
      expect(row.isPaid, isFalse);
    },
  );

  test('credit expense creates invoice row for billing cycle', () async {
    final AppDatabase db = AppDatabase.memory();
    addTearDown(db.close);
    final FinanceLocalRepository repo = FinanceLocalRepository(db);
    final int cardId = await repo.insertCreditCard(
      name: 'Visa',
      limitInCents: 5_000_000,
      closingDay: 15,
      dueDay: 20,
    );
    await repo.insertFinanceTransaction(
      amountInCents: 1_200,
      transactionType: TransactionType.expense,
      category: 'shop',
      description: 'online',
      dateUtc: DateTime.utc(2026, 4, 10),
      paymentMethod: PaymentMethod.credit,
      cardId: cardId,
    );
    final List<Invoice> invs = await db.select(db.invoices).get();
    expect(invs, hasLength(1));
    expect(invs.single.cardId, cardId);
    expect(invs.single.month, 4);
    expect(invs.single.year, 2026);
    expect(invs.single.totalInCents, 1_200);
    expect(invs.single.isPaid, isFalse);
  });
}

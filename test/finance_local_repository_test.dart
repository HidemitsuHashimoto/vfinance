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
}

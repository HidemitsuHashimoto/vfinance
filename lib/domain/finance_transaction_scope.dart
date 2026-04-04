import 'package:vfinance/domain/transaction_enums.dart';

/// Whether this row is a credit-card expense (Cartões), not a ledger posting
/// (Lançamentos).
bool isCardCreditExpenseStorage({
  required String transactionTypeStorage,
  required String paymentMethodStorage,
  required int? cardId,
}) {
  return transactionTypeStorage == TransactionType.expense.storageName &&
      paymentMethodStorage == PaymentMethod.credit.storageName &&
      cardId != null;
}

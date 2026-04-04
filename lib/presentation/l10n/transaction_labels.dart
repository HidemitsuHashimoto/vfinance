import 'package:vfinance/domain/transaction_enums.dart';
import 'package:vfinance/l10n/app_localizations.dart';

String labelPaymentMethod(AppLocalizations l, PaymentMethod method) {
  return switch (method) {
    PaymentMethod.pix => l.paymentPix,
    PaymentMethod.debit => l.paymentDebit,
    PaymentMethod.credit => l.paymentCredit,
    PaymentMethod.boleto => l.paymentBoleto,
  };
}

String labelTransactionType(AppLocalizations l, TransactionType type) {
  return switch (type) {
    TransactionType.expense => l.transactionKindExpense,
    TransactionType.income => l.transactionKindIncome,
  };
}

String labelAccountTypeStorage(AppLocalizations l, String storage) {
  return switch (storage) {
    'checking' => l.accountTypeChecking,
    'savings' => l.accountTypeSavings,
    'cash' => l.accountTypeCash,
    String other => other,
  };
}

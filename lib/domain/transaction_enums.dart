/// Expense vs income; storage strings match [domain.md] / Room.
enum TransactionType {
  expense('EXPENSE'),
  income('INCOME');

  const TransactionType(this.storageName);

  final String storageName;

  static TransactionType parseStorage(String raw) {
    for (final TransactionType value in TransactionType.values) {
      if (value.storageName == raw) {
        return value;
      }
    }
    throw ArgumentError.value(raw, 'raw', 'Unknown TransactionType');
  }
}

/// How a transaction was paid; storage strings match [domain.md] / Room.
enum PaymentMethod {
  pix('PIX'),
  debit('DEBIT'),
  credit('CREDIT'),
  boleto('BOLETO');

  const PaymentMethod(this.storageName);

  final String storageName;

  static PaymentMethod parseStorage(String raw) {
    for (final PaymentMethod value in PaymentMethod.values) {
      if (value.storageName == raw) {
        return value;
      }
    }
    throw ArgumentError.value(raw, 'raw', 'Unknown PaymentMethod');
  }
}

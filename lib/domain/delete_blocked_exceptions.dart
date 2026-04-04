/// Thrown when [FinanceLocalRepository.deleteAccount] finds linked rows.
final class AccountDeleteBlockedException implements Exception {
  const AccountDeleteBlockedException();
}

/// Thrown when [FinanceLocalRepository.deleteCreditCard] finds linked rows.
final class CardDeleteBlockedException implements Exception {
  const CardDeleteBlockedException();
}

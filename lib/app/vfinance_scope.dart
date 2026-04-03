import 'package:flutter/material.dart';
import 'package:vfinance/data/local/finance_local_repository.dart';

/// Provides [FinanceLocalRepository] to the widget tree (manual DI).
class VfinanceScope extends InheritedWidget {
  const VfinanceScope({
    super.key,
    required this.repository,
    required super.child,
  });

  final FinanceLocalRepository repository;

  static FinanceLocalRepository of(BuildContext context) {
    final VfinanceScope? scope = context
        .getInheritedWidgetOfExactType<VfinanceScope>();
    assert(scope != null, 'VfinanceScope not found');
    return scope!.repository;
  }

  @override
  bool updateShouldNotify(covariant VfinanceScope oldWidget) {
    return repository != oldWidget.repository;
  }
}

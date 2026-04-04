import 'package:flutter/material.dart';
import 'package:vfinance/data/local/finance_local_repository.dart';
import 'package:vfinance/data/local/pay_cycle_anchor_store.dart';

/// Provides [FinanceLocalRepository] and [PayCycleAnchorStore] (manual DI).
class VfinanceScope extends InheritedWidget {
  const VfinanceScope({
    super.key,
    required this.repository,
    required this.payCycleAnchors,
    required super.child,
  });

  final FinanceLocalRepository repository;

  final PayCycleAnchorStore payCycleAnchors;

  static FinanceLocalRepository of(BuildContext context) {
    final VfinanceScope? scope = context
        .getInheritedWidgetOfExactType<VfinanceScope>();
    assert(scope != null, 'VfinanceScope not found');
    return scope!.repository;
  }

  static PayCycleAnchorStore payCycleAnchorsOf(BuildContext context) {
    final VfinanceScope? scope = context
        .getInheritedWidgetOfExactType<VfinanceScope>();
    assert(scope != null, 'VfinanceScope not found');
    return scope!.payCycleAnchors;
  }

  @override
  bool updateShouldNotify(covariant VfinanceScope oldWidget) {
    return repository != oldWidget.repository ||
        payCycleAnchors != oldWidget.payCycleAnchors;
  }
}

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists pay-cycle anchor days (1–31) for Paycheck Planning on the home
/// screen.
final class PayCycleAnchorStore extends ChangeNotifier {
  PayCycleAnchorStore(this._prefs);

  static const String _prefsKey = 'pay_cycle_anchor_days_v1';

  final SharedPreferences _prefs;

  /// Loads store from platform preferences.
  static Future<PayCycleAnchorStore> load() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return PayCycleAnchorStore(prefs);
  }

  /// Unique sorted anchor days in range 1–31.
  List<int> readAnchorDays() {
    final List<String>? raw = _prefs.getStringList(_prefsKey);
    if (raw == null || raw.isEmpty) {
      return <int>[];
    }
    final Set<int> unique = <int>{};
    for (final String s in raw) {
      final int? v = int.tryParse(s);
      if (v != null && v >= 1 && v <= 31) {
        unique.add(v);
      }
    }
    final List<int> out = unique.toList()..sort();
    return out;
  }

  /// Replaces stored days with [days] (validated, deduped, sorted).
  Future<void> setAnchorDays(List<int> days) async {
    final Set<int> unique = <int>{};
    for (final int d in days) {
      if (d >= 1 && d <= 31) {
        unique.add(d);
      }
    }
    final List<int> sorted = unique.toList()..sort();
    final List<String> asStrings = sorted.map((int e) => e.toString()).toList();
    await _prefs.setStringList(_prefsKey, asStrings);
    notifyListeners();
  }
}

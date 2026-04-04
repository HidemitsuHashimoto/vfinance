import 'package:flutter/widgets.dart';
import 'package:vfinance/app/vfinance_app.dart';
import 'package:vfinance/data/local/pay_cycle_anchor_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final PayCycleAnchorStore payCycleAnchors = await PayCycleAnchorStore.load();
  runApp(VfinanceApp(payCycleAnchors: payCycleAnchors));
}

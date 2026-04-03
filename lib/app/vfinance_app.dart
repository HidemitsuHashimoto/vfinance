import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:vfinance/app/app_router.dart';
import 'package:vfinance/app/app_theme.dart';
import 'package:vfinance/app/vfinance_scope.dart';
import 'package:vfinance/data/local/app_database.dart';
import 'package:vfinance/data/local/finance_local_repository.dart';

/// Root widget: opens SQLite, exposes [FinanceLocalRepository], [GoRouter].
class VfinanceApp extends StatefulWidget {
  const VfinanceApp({super.key});

  @override
  State<VfinanceApp> createState() => _VfinanceAppState();
}

class _VfinanceAppState extends State<VfinanceApp> {
  late final AppDatabase _database;
  late final FinanceLocalRepository _repository;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _database = AppDatabase.connect();
    _repository = FinanceLocalRepository(_database);
    _router = createAppRouter();
  }

  @override
  void dispose() {
    _database.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return VfinanceScope(
      repository: _repository,
      child: MaterialApp.router(
        title: 'vfinance',
        theme: buildAppLightTheme(),
        routerConfig: _router,
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: const <Locale>[Locale('pt', 'BR')],
      ),
    );
  }
}

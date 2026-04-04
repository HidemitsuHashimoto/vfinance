import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vfinance/presentation/accounts/add_account_screen.dart';
import 'package:vfinance/presentation/accounts/accounts_screen.dart';
import 'package:vfinance/presentation/backup/backup_screen.dart';
import 'package:vfinance/presentation/cards/add_card_screen.dart';
import 'package:vfinance/presentation/cards/cards_screen.dart';
import 'package:vfinance/presentation/home/home_screen.dart';
import 'package:vfinance/presentation/shell/app_shell.dart';
import 'package:vfinance/presentation/transactions/add_transaction_screen.dart';
import 'package:vfinance/presentation/transactions/transactions_screen.dart';

/// Root navigator for full-screen routes (hides bottom bar).
final GlobalKey<NavigatorState> appRootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'appRoot',
);

/// Declarative routes (Material / Android).
GoRouter createAppRouter() {
  return GoRouter(
    navigatorKey: appRootNavigatorKey,
    initialLocation: '/home',
    routes: <RouteBase>[
      StatefulShellRoute.indexedStack(
        builder:
            (
              BuildContext context,
              GoRouterState state,
              StatefulNavigationShell navigationShell,
            ) {
              return AppShell(navigationShell: navigationShell);
            },
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/home',
                builder: (BuildContext context, GoRouterState state) {
                  return const HomeScreen();
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/accounts',
                builder: (BuildContext context, GoRouterState state) {
                  return const AccountsScreen();
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/transactions',
                builder: (BuildContext context, GoRouterState state) {
                  return const TransactionsScreen();
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/cards',
                builder: (BuildContext context, GoRouterState state) {
                  return const CardsScreen();
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/backup',
                builder: (BuildContext context, GoRouterState state) {
                  return const BackupScreen();
                },
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        parentNavigatorKey: appRootNavigatorKey,
        path: '/accounts/add',
        builder: (BuildContext context, GoRouterState state) {
          return const AddAccountScreen();
        },
      ),
      GoRoute(
        parentNavigatorKey: appRootNavigatorKey,
        path: '/accounts/edit/:id',
        builder: (BuildContext context, GoRouterState state) {
          final int id = int.parse(state.pathParameters['id']!);
          return AddAccountScreen(accountId: id);
        },
      ),
      GoRoute(
        parentNavigatorKey: appRootNavigatorKey,
        path: '/transactions/add',
        builder: (BuildContext context, GoRouterState state) {
          return const AddTransactionScreen();
        },
      ),
      GoRoute(
        parentNavigatorKey: appRootNavigatorKey,
        path: '/transactions/edit/:id',
        builder: (BuildContext context, GoRouterState state) {
          final int id = int.parse(state.pathParameters['id']!);
          return AddTransactionScreen(transactionId: id);
        },
      ),
      GoRoute(
        parentNavigatorKey: appRootNavigatorKey,
        path: '/cards/:cardId/add-expense',
        builder: (BuildContext context, GoRouterState state) {
          final int cardId = int.parse(state.pathParameters['cardId']!);
          return AddTransactionScreen(
            initialCardId: cardId,
            forceCardCreditFlow: true,
          );
        },
      ),
      GoRoute(
        parentNavigatorKey: appRootNavigatorKey,
        path: '/cards/expense/edit/:id',
        builder: (BuildContext context, GoRouterState state) {
          final int id = int.parse(state.pathParameters['id']!);
          return AddTransactionScreen(
            transactionId: id,
            forceCardCreditFlow: true,
          );
        },
      ),
      GoRoute(
        parentNavigatorKey: appRootNavigatorKey,
        path: '/cards/add',
        builder: (BuildContext context, GoRouterState state) {
          return const AddCardScreen();
        },
      ),
      GoRoute(
        parentNavigatorKey: appRootNavigatorKey,
        path: '/cards/edit/:id',
        builder: (BuildContext context, GoRouterState state) {
          final int id = int.parse(state.pathParameters['id']!);
          return AddCardScreen(cardId: id);
        },
      ),
    ],
  );
}

import 'package:flutter/widgets.dart';

/// Pops the current route using the root [Navigator].
///
/// Detail screens pushed with go_router [parentNavigatorKey] sit on the root
/// stack. Using [Navigator.pop] avoids [GoRouterDelegate] code that walks
/// shell branches with `navigatorKey.currentState!`, which can throw if a
/// branch navigator is not mounted yet.
void popCurrentRoute(BuildContext context) {
  if (!context.mounted) {
    return;
  }
  final NavigatorState? navigator = Navigator.maybeOf(
    context,
    rootNavigator: true,
  );
  if (navigator != null && navigator.canPop()) {
    navigator.pop();
  }
}

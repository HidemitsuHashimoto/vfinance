---
name: flutter-jank-streambuilder
description: >-
  Diagnoses Flutter UI jank (skipped frames, Davey, main-thread work) tied to
  StreamBuilder, Drift/sqflite watch streams, and IME/viewport churn. Use when
  logs mention Choreographer skipped frames, Davey, FlutterJNI viewport metrics,
  or when reviewing StreamBuilder + repository.watch() usage in Dart/Flutter.
---

# Flutter jank: StreamBuilder and watch streams

## Core rule

**Never pass a freshly created `Stream` instance to `StreamBuilder` from a
`build` method** when that method runs often (parent rebuilds, `setState`, theme,
keyboard insets). `StreamBuilder` compares the `stream` argument by identity;
a new instance cancels the previous subscription and subscribes again, which is
expensive and can spam the main isolate (Drift `.watch()` builds a new stream
per call).

## Fix pattern (StatefulWidget)

Cache streams when the data source is stable; refresh if the injected
repository (or scope) changes:

```dart
FinanceLocalRepository? _repositoryForStreams;
Stream<List<Account>>? _accountsStream;

@override
void didChangeDependencies() {
  super.didChangeDependencies();
  final FinanceLocalRepository repo = VfinanceScope.of(context);
  if (_repositoryForStreams != repo) {
    _repositoryForStreams = repo;
    _accountsStream = repo.watchAccounts();
  }
}

@override
Widget build(BuildContext context) {
  return StreamBuilder<List<Account>>(
    stream: _accountsStream!,
    builder: ...
  );
}
```

`didChangeDependencies` runs before the first `build`, so `_accountsStream` is
set before use. If tests omit `InheritedWidget` scope, they fail early (same as
before).

## StatelessWidget + StreamBuilder

Prefer **StatefulWidget** for screens that subscribe to DB streams, or extract a
small **private** `StatefulWidget` whose only job is to hold cached streams.

## Nested StreamBuilder

Each level needs a **stable** stream reference. Cache both streams in
`didChangeDependencies` (see `CardsScreen`-style nested builders).

## Repo-wide audit (vfinance)

Search for anti-pattern:

```bash
rg 'stream:\\s*repo\\.watch' lib/
rg 'StreamBuilder' lib/presentation
```

Also avoid unused `repo` locals left in `build` after caching streams.

## Related symptoms (not always a bug)

- **IME / keyboard**: `ImeTracker`, `Sending viewport metrics`, Davey on focus
  changes can be normal; still avoid redundant stream churn on those rebuilds.
- **Profile**: use Flutter DevTools Performance and timeline to confirm.

import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

class Accounts extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get name => text()();

  TextColumn get type => text()();

  IntColumn get balanceInCents => integer()();
}

class FinanceTransactions extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get amountInCents => integer()();

  TextColumn get transactionType => text()();

  TextColumn get category => text()();

  TextColumn get description => text()();

  IntColumn get dateUtcMillis => integer()();

  TextColumn get paymentMethod => text()();

  IntColumn get accountId => integer().nullable()();

  IntColumn get cardId => integer().nullable()();

  IntColumn get installmentId => integer().nullable()();
}

@DriftDatabase(tables: [Accounts, FinanceTransactions])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  factory AppDatabase.connect() {
    return AppDatabase(_openExecutor());
  }

  factory AppDatabase.memory() {
    return AppDatabase(NativeDatabase.memory());
  }

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
    );
  }
}

QueryExecutor _openExecutor() {
  return LazyDatabase(() async {
    final Directory dir = await getApplicationDocumentsDirectory();
    final File file = File(p.join(dir.path, 'vfinance.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}

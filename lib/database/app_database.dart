import 'package:drift/drift.dart';
import 'package:drift_sqflite/drift_sqflite.dart';

import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [FavoriteItems, ListingDrafts])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;
}

QueryExecutor _openConnection() {
  return SqfliteQueryExecutor.inDatabaseFolder(
    path: 'campus_marketplace.db',
    logStatements: false,
  );
}

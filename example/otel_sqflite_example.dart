// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

// Traced sqflite usage: each traced call emits one CLIENT span named
// `sqlite <op> [<table>]` with `db.system.name=sqlite`,
// `db.operation.name=<op>`, `db.collection.name=<table>` (when known)
// and `db.query.text=<sql>` (for raw operations).

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:otel_sqflite/otel_sqflite.dart';
// sqflite_common's `Database` clashes with the OTel semconv `Database`
// enum; the traced extension targets `DatabaseExecutor` anyway.
import 'package:sqflite_common/sqlite_api.dart' hide Database;

/// Runs a handful of traced operations against [db]. The extension is
/// on [DatabaseExecutor], so the same calls work on a `Database` or
/// inside a `Transaction`.
Future<void> demo(DatabaseExecutor db) async {
  await db.tracedExecute(
    'CREATE TABLE IF NOT EXISTS users (id INTEGER PRIMARY KEY, name TEXT)',
  );

  final id = await db.tracedInsert('users', {'name': 'Ada'});
  await db.tracedUpdate(
    'users',
    {'name': 'Ada Lovelace'},
    where: 'id = ?',
    whereArgs: [id],
  );

  final rows = await db.tracedQuery(
    'users',
    where: 'name LIKE ?',
    whereArgs: ['Ada%'],
  );
  print('queried ${rows.length} row(s)');

  final counts = await db.tracedRawQuery('SELECT COUNT(*) AS n FROM users');
  print('total: ${counts.single['n']}');

  await db.tracedDelete('users', where: 'id = ?', whereArgs: [id]);

  // Spans can be suppressed for a scope, e.g. noisy housekeeping:
  await runWithoutSqfliteInstrumentationAsync(() async {
    await db.tracedExecute('VACUUM');
  });
}

/// Returns the database for the demo, or `null` when no sqflite
/// database factory is wired up (the default for this pure-Dart
/// example — sqflite needs a platform-specific factory).
///
/// In a Flutter app (package:sqflite):
///
///     return openDatabase('app.db');
///
/// In pure Dart (package:sqflite_common_ffi):
///
///     databaseFactory = databaseFactoryFfi;
///     return databaseFactory.openDatabase(inMemoryDatabasePath);
Future<DatabaseExecutor?> openExampleDatabase() async => null;

Future<void> main() async {
  // Configure exporters/endpoint via the standard OTEL_* environment
  // variables (e.g. OTEL_EXPORTER_OTLP_ENDPOINT).
  await OTel.initialize(serviceName: 'otel-sqflite-example');

  final db = await openExampleDatabase();
  if (db != null) {
    await demo(db);
  }

  await OTel.shutdown();
}

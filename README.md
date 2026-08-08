# otel_sqflite

OpenTelemetry instrumentation for
[`package:sqflite`](https://pub.dev/packages/sqflite) /
[`package:sqflite_common`](https://pub.dev/packages/sqflite_common).

```dart
final db = await openDatabase('app.db');

final users = await db.tracedQuery('users', where: 'active = ?', whereArgs: [1]);
final id = await db.tracedInsert('users', {'name': 'Alice'});
await db.tracedUpdate('users', {'name': 'Alicia'}, where: 'id = ?', whereArgs: [id]);
await db.tracedDelete('users', where: 'id = ?', whereArgs: [id]);

final rows = await db.tracedRawQuery(
  'SELECT * FROM users WHERE created > ?',
  [DateTime.now().subtract(Duration(days: 7)).millisecondsSinceEpoch],
);

await db.tracedExecute('CREATE INDEX idx_users_name ON users(name)');
```

Each call emits a CLIENT span:
- name: `sqlite <op> [<table>]`
- `db.system.name = sqlite`
- `db.operation.name = query` / `insert` / `update` / `delete` / `raw_query` / `execute`
- `db.collection.name = <table>` (when applicable)
- `db.query.text = <sql>` (for raw operations)

The extension is on `DatabaseExecutor`, so the same methods work
inside `db.transaction((txn) async { await txn.tracedInsert(...); })`.

Suppression: `runWithoutSqfliteInstrumentationAsync`.

## Caveats

- For `tracedRawQuery` / `tracedExecute`, the raw SQL string is
  recorded as `db.query.text`. **If you concatenated parameter
  values into the SQL string** (instead of using `?`
  placeholders), those values land in the trace. Use bound
  parameters.

## License

Apache 2.0

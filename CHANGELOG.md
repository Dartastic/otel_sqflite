# Changelog

## [0.1.0] - 2026-08-10

### Added

- Extension methods on `DatabaseExecutor` (covers both
  `Database` and `Transaction`): `tracedQuery`, `tracedInsert`,
  `tracedUpdate`, `tracedDelete`, `tracedRawQuery`,
  `tracedExecute`. Each opens a CLIENT span with
  `db.system.name=sqlite`, `db.collection.name=<table>`,
  `db.operation.name`. Raw operations also record `db.query.text`.
- `tracedSqfliteCall<R>` — generic helper for testing or custom
  call sites.
- `DatabaseException`-aware error handling: `error.type` is set
  to `DatabaseException` for known sqflite errors, otherwise to
  the runtime class name.
- Zone-scoped suppression
  (`runWithoutSqfliteInstrumentation` and async variant).
- 4 tests via the generic helper.

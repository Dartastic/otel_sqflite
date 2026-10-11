# Changelog

## [1.0.0-wip]

### Changed

- Requires `dartastic_opentelemetry ^1.1.0-beta.17` and
  `dartastic_opentelemetry_api >=1.0.0-rc.4 <1.0.0-rc.5`.
- First 1.0 release: the public API of this package is stable and
  follows semantic versioning from here on.

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

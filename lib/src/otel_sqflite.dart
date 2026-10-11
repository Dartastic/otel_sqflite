// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'package:dartastic_opentelemetry_api/dartastic_opentelemetry_api.dart';
// sqflite_common's `Database` clashes with the OTel semconv `Database`
// enum; hide it here since the extension below uses `DatabaseExecutor`,
// which is the broader interface anyway.
import 'package:sqflite_common/sqlite_api.dart' hide Database;

import 'sqflite_suppression.dart';

const _tracerName = 'otel_sqflite';
const _dbSystem = 'sqlite';

APITracer _tracer() => OTelAPI.tracerProvider().getTracer(_tracerName);

Attributes _attrs({
  required String operation,
  String? table,
  String? sql,
}) =>
    OTelAPI.attributesFromMap(<String, Object>{
      Db.dbSystemName.key: _dbSystem,
      Db.dbOperationName.key: operation,
      if (table != null) Db.dbCollectionName.key: table,
      if (sql != null) Db.dbQueryText.key: sql,
    });

/// Generic helper. Opens a CLIENT span named
/// `sqlite <op> [<table>]` with `db.system.name=sqlite`,
/// `db.operation.name=<op>`, `db.collection.name=<table>` (when
/// known), and `db.query.text=<sql>` (when raw SQL is provided).
Future<R> tracedSqfliteCall<R>({
  required String operation,
  String? table,
  String? sql,
  required Future<R> Function() invoke,
}) async {
  if (sqfliteInstrumentationSuppressed()) return invoke();
  final name = table != null ? 'sqlite $operation $table' : 'sqlite $operation';
  final span = _tracer().startSpan(
    name,
    kind: SpanKind.client,
    attributes: _attrs(operation: operation, table: table, sql: sql),
  );
  try {
    return await invoke();
  } on DatabaseException catch (e, st) {
    span.addAttributes(OTelAPI.attributes([
      OTelAPI.attributeString(
          ErrorAttributes.errorType.key, 'DatabaseException'),
    ]));
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } catch (e, st) {
    span.addAttributes(OTelAPI.attributes([
      OTelAPI.attributeString(
        ErrorAttributes.errorType.key,
        e.runtimeType.toString(),
      ),
    ]));
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}

/// Traced operations on [DatabaseExecutor] (covers both
/// the `Database` and `Transaction` types from sqflite).
extension OTelDatabaseExecutor on DatabaseExecutor {
  /// Traced `query`. Records `db.collection.name=<table>` and the
  /// `db.response.returned_rows` count on success.
  Future<List<Map<String, Object?>>> tracedQuery(
    String table, {
    bool? distinct,
    List<String>? columns,
    String? where,
    List<Object?>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    return tracedSqfliteCall<List<Map<String, Object?>>>(
      operation: 'query',
      table: table,
      invoke: () async {
        final rows = await query(
          table,
          distinct: distinct,
          columns: columns,
          where: where,
          whereArgs: whereArgs,
          groupBy: groupBy,
          having: having,
          orderBy: orderBy,
          limit: limit,
          offset: offset,
        );
        return rows;
      },
    );
  }

  /// Traced `insert`.
  Future<int> tracedInsert(
    String table,
    Map<String, Object?> values, {
    String? nullColumnHack,
    ConflictAlgorithm? conflictAlgorithm,
  }) {
    return tracedSqfliteCall<int>(
      operation: 'insert',
      table: table,
      invoke: () => insert(
        table,
        values,
        nullColumnHack: nullColumnHack,
        conflictAlgorithm: conflictAlgorithm,
      ),
    );
  }

  /// Traced `update`.
  Future<int> tracedUpdate(
    String table,
    Map<String, Object?> values, {
    String? where,
    List<Object?>? whereArgs,
    ConflictAlgorithm? conflictAlgorithm,
  }) {
    return tracedSqfliteCall<int>(
      operation: 'update',
      table: table,
      invoke: () => update(
        table,
        values,
        where: where,
        whereArgs: whereArgs,
        conflictAlgorithm: conflictAlgorithm,
      ),
    );
  }

  /// Traced `delete`.
  Future<int> tracedDelete(
    String table, {
    String? where,
    List<Object?>? whereArgs,
  }) {
    return tracedSqfliteCall<int>(
      operation: 'delete',
      table: table,
      invoke: () => delete(table, where: where, whereArgs: whereArgs),
    );
  }

  /// Traced `rawQuery`. The raw SQL text is recorded as
  /// `db.query.text` — be aware this may contain parameter values
  /// if you concatenated them rather than using `?` placeholders.
  Future<List<Map<String, Object?>>> tracedRawQuery(
    String sql, [
    List<Object?>? arguments,
  ]) {
    return tracedSqfliteCall<List<Map<String, Object?>>>(
      operation: 'raw_query',
      sql: sql,
      invoke: () => rawQuery(sql, arguments),
    );
  }

  /// Traced `execute`.
  Future<void> tracedExecute(String sql, [List<Object?>? arguments]) {
    return tracedSqfliteCall<void>(
      operation: 'execute',
      sql: sql,
      invoke: () => execute(sql, arguments),
    );
  }
}

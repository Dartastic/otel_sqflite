// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:otel_sqflite/otel_sqflite.dart';
import 'package:test/test.dart';

class _MemorySpanExporter implements SpanExporter {
  final List<Span> spans = [];
  bool _shutdown = false;

  @override
  Future<void> export(List<Span> s) async {
    if (_shutdown) return;
    spans.addAll(s);
  }

  @override
  Future<void> forceFlush() async {}

  @override
  Future<void> shutdown() async {
    _shutdown = true;
  }
}

Map<String, Object> _attrs(Span span) =>
    {for (final a in span.attributes.toList()) a.key: a.value};

void main() {
  group('tracedSqfliteCall', () {
    late _MemorySpanExporter exporter;

    setUp(() async {
      await OTel.reset();
      exporter = _MemorySpanExporter();
      await OTel.initialize(
        serviceName: 'sqflite-otel-test',
        detectPlatformResources: false,
        spanProcessor: SimpleSpanProcessor(exporter),
      );
    });

    tearDown(() async {
      await OTel.shutdown();
      await OTel.reset();
    });

    test('emits CLIENT span with db.* attrs + table', () async {
      await tracedSqfliteCall<int>(
        operation: 'insert',
        table: 'users',
        invoke: () async => 1,
      );

      final span = exporter.spans.single;
      expect(span.kind, equals(SpanKind.client));
      expect(span.name, equals('sqlite insert users'));
      final attrs = _attrs(span);
      expect(attrs[Db.dbSystemName.key], equals('sqlite'));
      expect(attrs[Db.dbOperationName.key], equals('insert'));
      expect(attrs[Db.dbCollectionName.key], equals('users'));
    });

    test('records SQL text for raw operations', () async {
      const sql = 'SELECT * FROM users WHERE active = ?';
      await tracedSqfliteCall<void>(
        operation: 'raw_query',
        sql: sql,
        invoke: () async {},
      );
      final attrs = _attrs(exporter.spans.single);
      expect(attrs[Db.dbQueryText.key], equals(sql));
    });

    test('exception flips span to Error', () async {
      await expectLater(
        tracedSqfliteCall<int>(
          operation: 'insert',
          table: 'users',
          invoke: () async => throw StateError('locked'),
        ),
        throwsStateError,
      );
      final span = exporter.spans.single;
      expect(span.status, equals(SpanStatusCode.Error));
      expect(_attrs(span)[ErrorAttributes.errorType.key], equals('StateError'));
    });

    test('runWithoutSqfliteInstrumentationAsync bypasses spans', () async {
      await runWithoutSqfliteInstrumentationAsync(() async {
        await tracedSqfliteCall<int>(
          operation: 'insert',
          table: 'users',
          invoke: () async => 1,
        );
      });
      expect(exporter.spans, isEmpty);
    });
  });
}

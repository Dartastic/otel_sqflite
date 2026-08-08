// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'dart:async';

const Symbol _suppressKey = #otel_sqflite_suppress;

/// Whether sqflite instrumentation is suppressed in the current [Zone]
/// (i.e. the caller is inside [runWithoutSqfliteInstrumentation] or
/// [runWithoutSqfliteInstrumentationAsync]).
bool sqfliteInstrumentationSuppressed() {
  return Zone.current[_suppressKey] == true;
}

/// Runs [body] with sqflite instrumentation suppressed: no spans are
/// emitted for traced calls made within it.
T runWithoutSqfliteInstrumentation<T>(T Function() body) {
  return runZoned(body, zoneValues: {_suppressKey: true});
}

/// Async variant of [runWithoutSqfliteInstrumentation]: awaited traced
/// calls inside [body] emit no spans.
Future<T> runWithoutSqfliteInstrumentationAsync<T>(
  Future<T> Function() body,
) {
  return runZoned(body, zoneValues: {_suppressKey: true});
}

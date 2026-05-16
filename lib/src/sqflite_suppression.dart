// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'dart:async';

const Symbol _suppressKey = #otel_sqflite_suppress;

bool sqfliteInstrumentationSuppressed() {
  return Zone.current[_suppressKey] == true;
}

T runWithoutSqfliteInstrumentation<T>(T Function() body) {
  return runZoned(body, zoneValues: {_suppressKey: true});
}

Future<T> runWithoutSqfliteInstrumentationAsync<T>(
  Future<T> Function() body,
) {
  return runZoned(body, zoneValues: {_suppressKey: true});
}

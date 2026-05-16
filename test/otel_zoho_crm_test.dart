// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:dartastic_opentelemetry/testing.dart';
import 'package:otel_zoho_crm/otel_zoho_crm.dart';
import 'package:test/test.dart';

void main() {
  late TestHarness harness;
  late InMemorySpanExporter spans;

  setUpAll(() async {
    harness = await maybeInitializeOtelForTest(
      serviceName: 'otel_zoho_crm-test',
    );
    spans = harness.spans;
  });

  setUp(() => harness.clear());

  Map<String, Object> attrsOf(Span s) =>
      {for (final a in s.attributes.toList()) a.key: a.value};

  test('records.upsert records module + dc + credits', () async {
    await tracedZohoCrm<String>(
      operation: 'records.upsert',
      module: 'Deals',
      dataCenter: 'eu',
      invoke: () async => const ZohoCrmCallResult(
        value: 'ok',
        result: ZohoCrmResult(
          module: 'Deals',
          dataCenter: 'eu',
          apiCreditsRemaining: 4321,
          layoutId: 'lyt-1',
          tier: 'enterprise',
          statusCode: 200,
        ),
      ),
    );
    final a = attrsOf(spans.findSpanByName('zoho_crm records.upsert')!);
    expect(a['zoho_crm.module'], 'Deals');
    expect(a['zoho_crm.data_center'], 'eu');
    expect(a['zoho_crm.api_credits.remaining'], 4321);
    expect(a['zoho_crm.layout.id'], 'lyt-1');
    expect(a['zoho_crm.tier'], 'enterprise');
  });

  test('blueprint.execute records transition', () async {
    await tracedZohoCrm<String>(
      operation: 'blueprint.execute',
      invoke: () async => const ZohoCrmCallResult(
        value: 'ok',
        result: ZohoCrmResult(blueprintTransitionId: 'tr-1'),
      ),
    );
    final a = attrsOf(spans.findSpanByName('zoho_crm blueprint.execute')!);
    expect(a['zoho_crm.blueprint.transition_id'], 'tr-1');
  });

  test('suppression skips spans', () async {
    await runWithoutZohoCrmInstrumentationAsync(() async {
      await tracedZohoCrm<String>(
        operation: 'records.list',
        invoke: () async => const ZohoCrmCallResult(value: 'v'),
      );
    });
    expect(spans.findSpansStartingWith('zoho_crm '), isEmpty);
  });
}

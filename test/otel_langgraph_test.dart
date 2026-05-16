// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:dartastic_opentelemetry/testing.dart';
import 'package:otel_langgraph/otel_langgraph.dart';
import 'package:test/test.dart';

void main() {
  late TestHarness harness;
  late InMemorySpanExporter spans;

  setUpAll(() async {
    harness = await maybeInitializeOtelForTest(
      serviceName: 'otel_langgraph-test',
    );
    spans = harness.spans;
  });

  setUp(() => harness.clear());

  Map<String, Object> attrsOf(Span s) =>
      {for (final a in s.attributes.toList()) a.key: a.value};

  test('graph.invoke records thread + node + state patch', () async {
    await tracedLanggraph<String>(
      operation: 'graph.invoke',
      invoke: () async => const LanggraphCallResult(
        value: 'ok',
        result: LanggraphResult(
          assistantId: 'asst_1',
          threadId: 'thr_1',
          runId: 'run_1',
          graphId: 'customer_support_graph',
          checkpointId: 'ckpt_42',
          nodeName: 'classify_intent',
          edgeTo: 'route_to_billing',
          streamMode: 'values',
          runStatus: 'success',
          stepCount: 4,
          recursionLimit: 25,
          statePatchKeys: 'intent,confidence,routing_decision',
          deploymentRevision: 'rev_v8',
          statusCode: 200,
        ),
      ),
    );
    final a = attrsOf(spans.findSpanByName('langgraph graph.invoke')!);
    expect(a['langgraph.node.name'], 'classify_intent');
    expect(a['langgraph.edge.to'], 'route_to_billing');
    expect(a['langgraph.stream.mode'], 'values');
    expect(
        a['langgraph.state.patch_keys'], 'intent,confidence,routing_decision');
    expect(a['langgraph.deployment.revision'], 'rev_v8');
  });

  test('interrupted run records interrupt reason', () async {
    await tracedLanggraph<String>(
      operation: 'run.wait',
      invoke: () async => const LanggraphCallResult(
        value: 'ok',
        result: LanggraphResult(
          threadId: 'thr_1',
          runStatus: 'interrupted',
          interrupted: true,
          interruptReason: 'human-approval',
          nodeName: 'approve_refund',
        ),
      ),
    );
    final a = attrsOf(spans.findSpanByName('langgraph run.wait')!);
    expect(a['langgraph.interrupted'], true);
    expect(a['langgraph.interrupt.reason'], 'human-approval');
  });

  test('hit recursion_limit sets span error', () async {
    await tracedLanggraph<String>(
      operation: 'graph.invoke',
      invoke: () async => const LanggraphCallResult(
        value: 'ok',
        result: LanggraphResult(
          stepCount: 25,
          recursionLimit: 25,
        ),
      ),
    );
    expect(
      spans.findSpanByName('langgraph graph.invoke')!.status,
      SpanStatusCode.Error,
    );
  });

  test('suppression skips spans', () async {
    await runWithoutLanggraphInstrumentationAsync(() async {
      await tracedLanggraph<String>(
        operation: 'checkpoint.get',
        invoke: () async => const LanggraphCallResult(value: 'v'),
      );
    });
    expect(spans.findSpansStartingWith('langgraph '), isEmpty);
  });
}

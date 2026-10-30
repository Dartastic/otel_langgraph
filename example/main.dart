// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:otel_langgraph/otel_langgraph.dart';

/// Traces LangGraph calls with OpenTelemetry.
///
/// `otel_langgraph` depends on the OpenTelemetry API only, so the application
/// initializes an SDK once at startup. Wrap each LangGraph call in
/// [tracedLanggraph]; the `invoke` callback makes the real call and reports what
/// came back, which is recorded on the span.
Future<void> main() async {
  await OTel.initialize(serviceName: 'langgraph-example');

  // Wraps a LangGraph call in a CLIENT span.
  final langgraphId = await tracedLanggraph<String>(
    operation: 'thread.create',
    invoke: () async {
      // Make the LangGraph call here, then report what it returned.
      const id = 'langgraph_8f3a2c';
      return const LanggraphCallResult(
          value: id,
          result: LanggraphResult(
              assistantId: 'assistant_8f3a2c',
              threadId: 'thread_8f3a2c',
              runId: 'run_8f3a2c',
              graphId: 'graph_8f3a2c',
              checkpointId: 'checkpoint_8f3a2c',
              checkpointNs: 'example',
              parentCheckpointId: 'parentcheckpoint_8f3a2c',
              nodeName: 'example',
              edgeTo: 'END',
              streamMode: 'values',
              runStatus: 'pending',
              interrupted: true,
              interruptReason: 'human-approval',
              stepCount: 3,
              recursionLimit: 25,
              statePatchKeys: 'active',
              deploymentRevision: 'example',
              statusCode: 201));
    },
  );
  OTelLog.info('tracedLanggraph thread.create returned $langgraphId');

  // Calls that should not be traced, such as health checks, run inside
  // runWithoutLanggraphInstrumentationAsync.
  await runWithoutLanggraphInstrumentationAsync(
    () => tracedLanggraph<String>(
      operation: 'thread.create',
      invoke: () async {
        const id = 'langgraph_8f3a2c';
        return const LanggraphCallResult(
            value: id,
            result: LanggraphResult(
                assistantId: 'assistant_8f3a2c',
                threadId: 'thread_8f3a2c',
                runId: 'run_8f3a2c',
                graphId: 'graph_8f3a2c',
                checkpointId: 'checkpoint_8f3a2c',
                checkpointNs: 'example',
                parentCheckpointId: 'parentcheckpoint_8f3a2c',
                nodeName: 'example',
                edgeTo: 'END',
                streamMode: 'values',
                runStatus: 'pending',
                interrupted: true,
                interruptReason: 'human-approval',
                stepCount: 3,
                recursionLimit: 25,
                statePatchKeys: 'active',
                deploymentRevision: 'example',
                statusCode: 201));
      },
    ),
  );

  await OTel.shutdown();
}

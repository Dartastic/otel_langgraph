// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry_api/dartastic_opentelemetry_api.dart';

import 'otel_langgraph_suppression.dart';

const _tracerName = 'dartastic_otel_libs_langgraph';

APITracer _tracer() => OTelAPI.tracerProvider().getTracer(_tracerName);

class LanggraphResult {
  /// Creates a result.
  const LanggraphResult({
    this.assistantId,
    this.threadId,
    this.runId,
    this.graphId,
    this.checkpointId,
    this.checkpointNs,
    this.parentCheckpointId,
    this.nodeName,
    this.edgeTo,
    this.streamMode,
    this.runStatus,
    this.interrupted,
    this.interruptReason,
    this.stepCount,
    this.recursionLimit,
    this.statePatchKeys,
    this.deploymentRevision,
    this.statusCode,
  });

  /// LangGraph Cloud assistant id (a config snapshot of a graph).
  final String? assistantId;

  /// Thread id — persistent conversational scope.
  final String? threadId;

  /// Specific run within the thread.
  final String? runId;

  final String? graphId;

  /// Checkpoint id (state snapshot — LangGraph's durability primitive).
  final String? checkpointId;

  /// Checkpoint namespace (used for subgraphs).
  final String? checkpointNs;

  /// Parent checkpoint when forked from history (time-travel).
  final String? parentCheckpointId;

  /// Current node executing.
  final String? nodeName;

  /// Target node the edge routed to (`END` for terminal).
  final String? edgeTo;

  /// `values` / `updates` / `messages` / `events` / `debug` / `custom`.
  final String? streamMode;

  /// `pending` / `running` / `success` / `error` / `interrupted` /
  /// `timeout`.
  final String? runStatus;

  /// `true` when the graph paused at an `interrupt()`.
  final bool? interrupted;

  /// User-friendly interrupt reason (e.g., `human-approval`,
  /// `tool-confirm`).
  final String? interruptReason;

  /// Number of supersteps executed.
  final int? stepCount;

  /// Configured `recursion_limit` (default 25).
  final int? recursionLimit;

  /// Comma-separated keys patched on the state in this step.
  final String? statePatchKeys;

  /// LangGraph Cloud deployment revision id.
  final String? deploymentRevision;

  final int? statusCode;
}

/// What a traced call returned: the value for the caller plus fields
/// recorded on the span.
class LanggraphCallResult<T> {
  /// Creates a call result.
  const LanggraphCallResult({required this.value, this.result});

  /// The value returned to the caller.
  final T value;
  final LanggraphResult? result;
}

/// Wraps a LangGraph call in a CLIENT span. [operation] is one of
/// `graph.invoke`, `graph.stream`, `graph.batch`, `thread.create`,
/// `thread.update_state`, `run.create`, `run.wait`, `run.stream`,
/// `run.cancel`, `checkpoint.get`, `checkpoint.list`,
/// `assistant.create`, `assistant.update`, `cron.create`.
Future<T> tracedLanggraph<T>({
  required String operation,
  required Future<LanggraphCallResult<T>> Function() invoke,
}) async {
  if (langgraphInstrumentationSuppressed()) {
    final r = await invoke();
    return r.value;
  }
  final m = <String, Object>{
    'rpc.system': 'langgraph',
    'rpc.method': operation,
    'langgraph.operation': operation,
  };

  final span = _tracer().startSpan(
    'langgraph $operation',
    kind: SpanKind.client,
    attributes: OTelAPI.attributesFromMap(m),
  );
  try {
    final r = await invoke();
    if (r.result != null) {
      final extras = <Attribute<Object>>[];
      if (r.result!.assistantId != null) {
        extras.add(OTelAPI.attributeString(
          'langgraph.assistant.id',
          r.result!.assistantId!,
        ));
      }
      if (r.result!.threadId != null) {
        extras.add(OTelAPI.attributeString(
          'langgraph.thread.id',
          r.result!.threadId!,
        ));
      }
      if (r.result!.runId != null) {
        extras.add(OTelAPI.attributeString(
          'langgraph.run.id',
          r.result!.runId!,
        ));
      }
      if (r.result!.graphId != null) {
        extras.add(OTelAPI.attributeString(
          'langgraph.graph.id',
          r.result!.graphId!,
        ));
      }
      if (r.result!.checkpointId != null) {
        extras.add(OTelAPI.attributeString(
          'langgraph.checkpoint.id',
          r.result!.checkpointId!,
        ));
      }
      if (r.result!.checkpointNs != null) {
        extras.add(OTelAPI.attributeString(
          'langgraph.checkpoint.ns',
          r.result!.checkpointNs!,
        ));
      }
      if (r.result!.parentCheckpointId != null) {
        extras.add(OTelAPI.attributeString(
          'langgraph.checkpoint.parent_id',
          r.result!.parentCheckpointId!,
        ));
      }
      if (r.result!.nodeName != null) {
        extras.add(OTelAPI.attributeString(
          'langgraph.node.name',
          r.result!.nodeName!,
        ));
      }
      if (r.result!.edgeTo != null) {
        extras.add(OTelAPI.attributeString(
          'langgraph.edge.to',
          r.result!.edgeTo!,
        ));
      }
      if (r.result!.streamMode != null) {
        extras.add(OTelAPI.attributeString(
          'langgraph.stream.mode',
          r.result!.streamMode!,
        ));
      }
      if (r.result!.runStatus != null) {
        extras.add(OTelAPI.attributeString(
          'langgraph.run.status',
          r.result!.runStatus!,
        ));
        if (r.result!.runStatus == 'error' ||
            r.result!.runStatus == 'timeout') {
          span.setStatus(
            SpanStatusCode.Error,
            'LangGraph run ${r.result!.runStatus}',
          );
        }
      }
      if (r.result!.interrupted != null) {
        extras.add(OTelAPI.attributeBool(
          'langgraph.interrupted',
          r.result!.interrupted!,
        ));
      }
      if (r.result!.interruptReason != null) {
        extras.add(OTelAPI.attributeString(
          'langgraph.interrupt.reason',
          r.result!.interruptReason!,
        ));
      }
      if (r.result!.stepCount != null) {
        extras.add(OTelAPI.attributeInt(
          'langgraph.step.count',
          r.result!.stepCount!,
        ));
      }
      if (r.result!.recursionLimit != null) {
        extras.add(OTelAPI.attributeInt(
          'langgraph.recursion.limit',
          r.result!.recursionLimit!,
        ));
        if (r.result!.stepCount != null &&
            r.result!.stepCount! >= r.result!.recursionLimit!) {
          span.setStatus(
            SpanStatusCode.Error,
            'LangGraph hit recursion_limit',
          );
        }
      }
      if (r.result!.statePatchKeys != null) {
        extras.add(OTelAPI.attributeString(
          'langgraph.state.patch_keys',
          r.result!.statePatchKeys!,
        ));
      }
      if (r.result!.deploymentRevision != null) {
        extras.add(OTelAPI.attributeString(
          'langgraph.deployment.revision',
          r.result!.deploymentRevision!,
        ));
      }
      if (r.result!.statusCode != null) {
        extras.add(OTelAPI.attributeInt(
          'http.response.status_code',
          r.result!.statusCode!,
        ));
        if (r.result!.statusCode! >= 400) {
          span.setStatus(
            SpanStatusCode.Error,
            'LangGraph HTTP ${r.result!.statusCode}',
          );
        }
      }
      if (extras.isNotEmpty) span.addAttributes(OTelAPI.attributes(extras));
    }
    return r.value;
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

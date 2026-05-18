// Licensed under the Dartastic Pro Software License Agreement.
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';

import 'otel_langgraph_suppression.dart';

const _tracerName = 'dartastic_otel_libs_langgraph';

Tracer _tracer() => OTel.tracerProvider().getTracer(_tracerName);

class LanggraphResult {
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

class LanggraphCallResult<T> {
  const LanggraphCallResult({required this.value, this.result});
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
    attributes: OTel.attributesFromMap(m),
  );
  try {
    final r = await invoke();
    if (r.result != null) {
      final extras = <Attribute<Object>>[];
      if (r.result!.assistantId != null) {
        extras.add(OTel.attributeString(
          'langgraph.assistant.id',
          r.result!.assistantId!,
        ));
      }
      if (r.result!.threadId != null) {
        extras.add(OTel.attributeString(
          'langgraph.thread.id',
          r.result!.threadId!,
        ));
      }
      if (r.result!.runId != null) {
        extras.add(OTel.attributeString(
          'langgraph.run.id',
          r.result!.runId!,
        ));
      }
      if (r.result!.graphId != null) {
        extras.add(OTel.attributeString(
          'langgraph.graph.id',
          r.result!.graphId!,
        ));
      }
      if (r.result!.checkpointId != null) {
        extras.add(OTel.attributeString(
          'langgraph.checkpoint.id',
          r.result!.checkpointId!,
        ));
      }
      if (r.result!.checkpointNs != null) {
        extras.add(OTel.attributeString(
          'langgraph.checkpoint.ns',
          r.result!.checkpointNs!,
        ));
      }
      if (r.result!.parentCheckpointId != null) {
        extras.add(OTel.attributeString(
          'langgraph.checkpoint.parent_id',
          r.result!.parentCheckpointId!,
        ));
      }
      if (r.result!.nodeName != null) {
        extras.add(OTel.attributeString(
          'langgraph.node.name',
          r.result!.nodeName!,
        ));
      }
      if (r.result!.edgeTo != null) {
        extras.add(OTel.attributeString(
          'langgraph.edge.to',
          r.result!.edgeTo!,
        ));
      }
      if (r.result!.streamMode != null) {
        extras.add(OTel.attributeString(
          'langgraph.stream.mode',
          r.result!.streamMode!,
        ));
      }
      if (r.result!.runStatus != null) {
        extras.add(OTel.attributeString(
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
        extras.add(OTel.attributeBool(
          'langgraph.interrupted',
          r.result!.interrupted!,
        ));
      }
      if (r.result!.interruptReason != null) {
        extras.add(OTel.attributeString(
          'langgraph.interrupt.reason',
          r.result!.interruptReason!,
        ));
      }
      if (r.result!.stepCount != null) {
        extras.add(OTel.attributeInt(
          'langgraph.step.count',
          r.result!.stepCount!,
        ));
      }
      if (r.result!.recursionLimit != null) {
        extras.add(OTel.attributeInt(
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
        extras.add(OTel.attributeString(
          'langgraph.state.patch_keys',
          r.result!.statePatchKeys!,
        ));
      }
      if (r.result!.deploymentRevision != null) {
        extras.add(OTel.attributeString(
          'langgraph.deployment.revision',
          r.result!.deploymentRevision!,
        ));
      }
      if (r.result!.statusCode != null) {
        extras.add(OTel.attributeInt(
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
      if (extras.isNotEmpty) span.addAttributes(OTel.attributes(extras));
    }
    return r.value;
  } catch (e, st) {
    span.addAttributes(OTel.attributes([
      OTel.attributeString(
        ErrorResource.errorType.key,
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

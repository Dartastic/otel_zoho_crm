// Licensed under the Dartastic Pro Software License Agreement.
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';

import 'otel_zoho_crm_suppression.dart';

const _tracerName = 'dartastic_otel_libs_zoho_crm';

Tracer _tracer() => OTel.tracerProvider().getTracer(_tracerName);

class ZohoCrmResult {
  const ZohoCrmResult({
    this.itemCount,
    this.moreRecords,
    this.module,
    this.dataCenter,
    this.apiCreditsRemaining,
    this.bulkJobId,
    this.blueprintTransitionId,
    this.layoutId,
    this.tier,
    this.requestId,
    this.statusCode,
  });

  /// `data.length`.
  final int? itemCount;

  /// `info.more_records`.
  final bool? moreRecords;

  /// `Leads` / `Contacts` / `Accounts` / `Deals` / `Tasks` / `Calls` /
  /// `Meetings` / `Cases` / `Products` / custom module name.
  final String? module;

  /// `us` / `eu` / `in` / `au` / `cn` / `jp` — Zoho data center
  /// (different hostnames, different latency).
  final String? dataCenter;

  /// `X-RATELIMIT-REMAINING` API credits remaining (Zoho prices
  /// per-day API-credit allowances; this is the cost dim).
  final int? apiCreditsRemaining;

  /// `id` from a bulk job submit.
  final String? bulkJobId;

  /// Blueprint transition id when calling `Transitions.execute` —
  /// drives custom workflow tracing.
  final String? blueprintTransitionId;

  /// `Layout.id` used for the record (multi-layout orgs).
  final String? layoutId;

  /// `free` / `standard` / `professional` / `enterprise` / `cuc` /
  /// `ultimate`.
  final String? tier;

  /// `X-Request-Id`.
  final String? requestId;

  final int? statusCode;
}

class ZohoCrmCallResult<T> {
  const ZohoCrmCallResult({required this.value, this.result});
  final T value;
  final ZohoCrmResult? result;
}

/// Wraps a Zoho CRM API call in a CLIENT span. [operation] is one of
/// `records.list`, `records.get`, `records.insert`, `records.update`,
/// `records.upsert`, `records.delete`, `records.search`,
/// `related_lists.list`, `mass_update.execute`, `mass_delete.execute`,
/// `bulk_read.create`, `bulk_read.result`, `bulk_write.create`,
/// `bulk_write.result`, `blueprint.transitions`, `blueprint.execute`,
/// `notifications.list`, `metadata.modules`, `metadata.layouts`.
Future<T> tracedZohoCrm<T>({
  required String operation,
  required Future<ZohoCrmCallResult<T>> Function() invoke,
  String? module,
  String? dataCenter,
}) async {
  if (zohoCrmInstrumentationSuppressed()) {
    final r = await invoke();
    return r.value;
  }
  final m = <String, Object>{
    'rpc.system': 'zoho_crm',
    'rpc.method': operation,
    'zoho_crm.operation': operation,
  };
  if (module != null) m['zoho_crm.module'] = module;
  if (dataCenter != null) m['zoho_crm.data_center'] = dataCenter;

  final span = _tracer().startSpan(
    'zoho_crm $operation',
    kind: SpanKind.client,
    attributes: OTel.attributesFromMap(m),
  );
  try {
    final r = await invoke();
    if (r.result != null) {
      final extras = <Attribute<Object>>[];
      if (r.result!.itemCount != null) {
        extras.add(OTel.attributeInt(
          'zoho_crm.item_count',
          r.result!.itemCount!,
        ));
      }
      if (r.result!.moreRecords != null) {
        extras.add(OTel.attributeBool(
          'zoho_crm.more_records',
          r.result!.moreRecords!,
        ));
      }
      if (r.result!.module != null) {
        extras.add(OTel.attributeString(
          'zoho_crm.module',
          r.result!.module!,
        ));
      }
      if (r.result!.dataCenter != null) {
        extras.add(OTel.attributeString(
          'zoho_crm.data_center',
          r.result!.dataCenter!,
        ));
      }
      if (r.result!.apiCreditsRemaining != null) {
        extras.add(OTel.attributeInt(
          'zoho_crm.api_credits.remaining',
          r.result!.apiCreditsRemaining!,
        ));
      }
      if (r.result!.bulkJobId != null) {
        extras.add(OTel.attributeString(
          'zoho_crm.bulk.job_id',
          r.result!.bulkJobId!,
        ));
      }
      if (r.result!.blueprintTransitionId != null) {
        extras.add(OTel.attributeString(
          'zoho_crm.blueprint.transition_id',
          r.result!.blueprintTransitionId!,
        ));
      }
      if (r.result!.layoutId != null) {
        extras.add(OTel.attributeString(
          'zoho_crm.layout.id',
          r.result!.layoutId!,
        ));
      }
      if (r.result!.tier != null) {
        extras.add(OTel.attributeString(
          'zoho_crm.tier',
          r.result!.tier!,
        ));
      }
      if (r.result!.requestId != null) {
        extras.add(OTel.attributeString(
          'zoho_crm.request.id',
          r.result!.requestId!,
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
            'Zoho CRM HTTP ${r.result!.statusCode}',
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

import 'package:belluga_now/domain/tenant_admin/tenant_admin_settings.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_value_parsers.dart';
import 'package:belluga_now/infrastructure/dal/dao/http/raw_json_envelope_decoder.dart';

class TenantAdminDomainsResponseDecoder {
  const TenantAdminDomainsResponseDecoder({
    RawJsonEnvelopeDecoder? envelopeDecoder,
  }) : _envelopeDecoder = envelopeDecoder ?? const RawJsonEnvelopeDecoder();

  final RawJsonEnvelopeDecoder _envelopeDecoder;

  List<TenantAdminDomainEntry> decodeDomainList(Object? rawResponse) {
    final rows = _envelopeDecoder.decodeListMap(
      rawResponse,
      label: 'tenant domains',
    );
    return rows.map(_mapDomain).toList(growable: false);
  }

  TenantAdminDomainEntry decodeDomainItem(Object? rawResponse) {
    final row = _envelopeDecoder.decodeItemMap(
      rawResponse,
      label: 'tenant domain',
    );
    return _mapDomain(row);
  }

  TenantAdminDomainEntry _mapDomain(Map<String, dynamic> row) {
    return TenantAdminDomainEntry(
      idValue: tenantAdminRequiredText(row['id'] ?? row['_id']),
      pathValue: tenantAdminRequiredText(row['path']),
      typeValue: tenantAdminRequiredText(row['type'] ?? 'web'),
      statusValue: tenantAdminDomainStatus(
        row['status'],
        deletedAt: row['deleted_at'],
      ),
      createdAtValue: tenantAdminOptionalDateTime(row['created_at']),
      updatedAtValue: tenantAdminOptionalDateTime(row['updated_at']),
      deletedAtValue: tenantAdminOptionalDateTime(row['deleted_at']),
    );
  }
}

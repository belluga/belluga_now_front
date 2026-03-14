import 'package:belluga_now/infrastructure/dal/dao/http/raw_json_envelope_decoder.dart';
import 'package:belluga_now/infrastructure/dal/dto/tenant_admin/tenant_admin_organization_dto.dart';

class TenantAdminOrganizationsResponseDecoder {
  const TenantAdminOrganizationsResponseDecoder({
    RawJsonEnvelopeDecoder? envelopeDecoder,
  }) : _envelopeDecoder = envelopeDecoder ?? const RawJsonEnvelopeDecoder();

  final RawJsonEnvelopeDecoder _envelopeDecoder;

  TenantAdminOrganizationDTO decodeOrganizationItem(Object? rawResponse) {
    return TenantAdminOrganizationDTO.fromJson(
      _envelopeDecoder.decodeItemMap(
        rawResponse,
        label: 'organization',
      ),
    );
  }

  List<TenantAdminOrganizationDTO> decodeOrganizationList(Object? rawResponse) {
    return _envelopeDecoder
        .decodeListMap(
          rawResponse,
          label: 'organizations',
        )
        .map(TenantAdminOrganizationDTO.fromJson)
        .toList(growable: false);
  }
}

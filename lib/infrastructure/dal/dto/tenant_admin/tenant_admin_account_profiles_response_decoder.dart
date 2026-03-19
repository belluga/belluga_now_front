import 'package:belluga_now/infrastructure/dal/dao/http/raw_json_envelope_decoder.dart';
import 'package:belluga_now/infrastructure/dal/dto/tenant_admin/tenant_admin_account_profile_dto.dart';
import 'package:belluga_now/infrastructure/dal/dto/tenant_admin/tenant_admin_profile_type_dto.dart';

class TenantAdminAccountProfilesResponseDecoder {
  const TenantAdminAccountProfilesResponseDecoder({
    RawJsonEnvelopeDecoder? envelopeDecoder,
  }) : _envelopeDecoder = envelopeDecoder ?? const RawJsonEnvelopeDecoder();

  final RawJsonEnvelopeDecoder _envelopeDecoder;

  TenantAdminAccountProfileDTO decodeAccountProfileItem(Object? rawResponse) {
    return TenantAdminAccountProfileDTO.fromJson(
      _envelopeDecoder.decodeItemMap(
        rawResponse,
        label: 'account profile',
      ),
    );
  }

  List<TenantAdminAccountProfileDTO> decodeAccountProfileList(
    Object? rawResponse,
  ) {
    return _envelopeDecoder
        .decodeListMap(
          rawResponse,
          label: 'account profiles',
        )
        .map(TenantAdminAccountProfileDTO.fromJson)
        .toList(growable: false);
  }

  TenantAdminProfileTypeDTO decodeProfileTypeItem(Object? rawResponse) {
    return TenantAdminProfileTypeDTO.fromJson(
      _envelopeDecoder.decodeItemMap(
        rawResponse,
        label: 'profile type',
      ),
    );
  }

  List<TenantAdminProfileTypeDTO> decodeProfileTypeList(Object? rawResponse) {
    return _envelopeDecoder
        .decodeListMap(
          rawResponse,
          label: 'profile types',
        )
        .map(TenantAdminProfileTypeDTO.fromJson)
        .toList(growable: false);
  }
}

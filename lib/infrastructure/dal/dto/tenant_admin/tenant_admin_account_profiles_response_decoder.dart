import 'package:belluga_now/infrastructure/dal/dao/http/raw_json_envelope_decoder.dart';
import 'package:belluga_now/infrastructure/dal/dto/tenant_admin/tenant_admin_account_profile_dto.dart';
import 'package:belluga_now/infrastructure/dal/dto/tenant_admin/tenant_admin_account_profile_candidate_dto.dart';
import 'package:belluga_now/infrastructure/dal/dto/tenant_admin/tenant_admin_nested_group_member_mutation_result_dto.dart';
import 'package:belluga_now/infrastructure/dal/dto/tenant_admin/tenant_admin_nested_group_member_page_dto.dart';
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

  TenantAdminAccountProfileCandidatePageDTO decodeCandidatePage(
    Object? rawResponse,
  ) {
    if (rawResponse is! Map) {
      throw const FormatException('Invalid account profile candidate page.');
    }

    return TenantAdminAccountProfileCandidatePageDTO.fromJson(
      Map<String, dynamic>.from(rawResponse),
    );
  }

  TenantAdminNestedGroupMemberPageDTO decodeNestedGroupMemberPage(
    Object? rawResponse,
  ) {
    if (rawResponse is! Map) {
      throw const FormatException('Invalid nested group member page.');
    }

    return TenantAdminNestedGroupMemberPageDTO.fromJson(
      Map<String, dynamic>.from(rawResponse),
    );
  }

  TenantAdminNestedGroupMemberMutationResultDTO
  decodeNestedGroupMemberMutationResult(Object? rawResponse) {
    final item = _envelopeDecoder.decodeItemMap(
      rawResponse,
      label: 'nested group member mutation result',
    );

    return TenantAdminNestedGroupMemberMutationResultDTO.fromJson(item);
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

  int decodeProjectionImpactCount(Object? rawResponse) {
    final item = _envelopeDecoder.decodeItemMap(
      rawResponse,
      label: 'profile type projection impact',
    );
    final rawCount = item['projection_count'];
    if (rawCount is num) {
      return rawCount.toInt();
    }
    return 0;
  }
}

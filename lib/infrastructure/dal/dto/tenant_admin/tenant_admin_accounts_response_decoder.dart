import 'package:belluga_now/infrastructure/dal/dao/http/raw_json_envelope_decoder.dart';
import 'package:belluga_now/infrastructure/dal/dto/tenant_admin/tenant_admin_account_dto.dart';
import 'package:belluga_now/infrastructure/dal/dto/tenant_admin/tenant_admin_account_profile_dto.dart';
import 'package:belluga_now/infrastructure/dal/dto/tenant_admin/tenant_admin_account_onboarding_response_dto.dart';

class TenantAdminAccountsResponseDecoder {
  const TenantAdminAccountsResponseDecoder({
    RawJsonEnvelopeDecoder? envelopeDecoder,
  }) : _envelopeDecoder = envelopeDecoder ?? const RawJsonEnvelopeDecoder();

  final RawJsonEnvelopeDecoder _envelopeDecoder;

  TenantAdminAccountDTO decodeAccountItem(Object? rawResponse) {
    return TenantAdminAccountDTO.fromJson(
      _envelopeDecoder.decodeItemMap(
        rawResponse,
        label: 'account',
      ),
    );
  }

  List<TenantAdminAccountDTO> decodeAccountList(Object? rawResponse) {
    return _envelopeDecoder
        .decodeListMap(
          rawResponse,
          label: 'accounts',
        )
        .map(TenantAdminAccountDTO.fromJson)
        .toList(growable: false);
  }

  TenantAdminAccountDTO decodeCreateAccountItem(Object? rawResponse) {
    final data = _envelopeDecoder.decodeItemMap(
      rawResponse,
      label: 'account create',
    );
    final account = data['account'];
    if (account is Map) {
      return TenantAdminAccountDTO.fromJson(Map<String, dynamic>.from(account));
    }
    return TenantAdminAccountDTO.fromJson(data);
  }

  TenantAdminAccountOnboardingResponseDTO decodeOnboarding(
    Object? rawResponse,
  ) {
    final data = _envelopeDecoder.decodeItemMap(
      rawResponse,
      label: 'account onboarding',
    );
    final accountRaw = data['account'];
    final accountProfileRaw = data['account_profile'];
    if (accountRaw is! Map || accountProfileRaw is! Map) {
      throw Exception('Unexpected account onboarding response shape.');
    }
    return TenantAdminAccountOnboardingResponseDTO(
      account: TenantAdminAccountDTO.fromJson(
        Map<String, dynamic>.from(accountRaw),
      ),
      accountProfile: TenantAdminAccountProfileDTO.fromJson(
        Map<String, dynamic>.from(accountProfileRaw),
      ),
    );
  }
}

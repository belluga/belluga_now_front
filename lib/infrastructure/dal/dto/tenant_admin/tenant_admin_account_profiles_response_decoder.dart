import 'package:belluga_now/infrastructure/dal/dao/http/raw_json_envelope_decoder.dart';
import 'package:belluga_now/infrastructure/dal/dto/tenant_admin/tenant_admin_account_profile_dto.dart';
import 'package:belluga_now/infrastructure/dal/dto/tenant_admin/tenant_admin_account_profile_candidate_dto.dart';
import 'package:belluga_now/infrastructure/dal/dto/tenant_admin/tenant_admin_nested_group_member_mutation_result_dto.dart';
import 'package:belluga_now/infrastructure/dal/dto/tenant_admin/tenant_admin_nested_group_member_page_dto.dart';
import 'package:belluga_now/infrastructure/dal/dto/tenant_admin/tenant_admin_profile_type_dto.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_nested_group_head_mutation_result.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_group_order_mutation_result.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile_gallery_snapshot.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_nested_group_label_mutation_result.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_nested_profile_group.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_count_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_value_parsers.dart';

class TenantAdminAccountProfilesResponseDecoder {
  const TenantAdminAccountProfilesResponseDecoder({
    RawJsonEnvelopeDecoder? envelopeDecoder,
  }) : _envelopeDecoder = envelopeDecoder ?? const RawJsonEnvelopeDecoder();

  final RawJsonEnvelopeDecoder _envelopeDecoder;

  TenantAdminAccountProfileDTO decodeAccountProfileItem(Object? rawResponse) {
    return TenantAdminAccountProfileDTO.fromJson(
      _envelopeDecoder.decodeItemMap(rawResponse, label: 'account profile'),
    );
  }

  TenantAdminAccountProfileGallerySnapshot decodeGallerySnapshot(
    Object? rawResponse,
  ) {
    return tenantAdminAccountProfileGallerySnapshotFromJson(
      _envelopeDecoder.decodeItemMap(rawResponse, label: 'gallery mutation'),
    );
  }

  List<TenantAdminAccountProfileDTO> decodeAccountProfileList(
    Object? rawResponse,
  ) {
    return _envelopeDecoder
        .decodeListMap(rawResponse, label: 'account profiles')
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

  TenantAdminNestedGroupHeadMutationResult decodeNestedGroupHeadMutationResult(
    Object? rawResponse,
  ) {
    final item = _envelopeDecoder.decodeItemMap(
      rawResponse,
      label: 'nested group head mutation result',
    );
    final rawGroups = item['nested_profile_groups'];
    if (rawGroups is! List) {
      throw const FormatException(
        'Invalid nested group head mutation response.',
      );
    }

    return TenantAdminNestedGroupHeadMutationResult(
      deletedGroupIdValue: tenantAdminOptionalText(item['deleted_group_id']),
      groups: rawGroups
          .whereType<Map>()
          .map((group) => Map<String, dynamic>.from(group))
          .map(_decodeNestedProfileGroup)
          .whereType<TenantAdminNestedProfileGroup>()
          .toList(growable: false),
    );
  }

  TenantAdminNestedGroupLabelMutationResult
  decodeNestedGroupLabelMutationResult(Object? rawResponse) {
    final item = _envelopeDecoder.decodeItemMap(
      rawResponse,
      label: 'nested group label mutation result',
    );
    final rawGroup = item['group'];
    if (rawGroup is! Map) {
      throw const FormatException(
        'Invalid nested group label mutation response.',
      );
    }
    final group = Map<String, dynamic>.from(rawGroup);
    final id = _asString(group['id']);
    final label = _asString(group['label']);
    if (id == null ||
        label == null ||
        id.trim().isEmpty ||
        label.trim().isEmpty) {
      throw const FormatException(
        'Invalid nested group label mutation response.',
      );
    }
    return TenantAdminNestedGroupLabelMutationResult(
      idValue: TenantAdminNestedProfileGroupTextValue(id),
      labelValue: TenantAdminNestedProfileGroupTextValue(label),
    );
  }

  TenantAdminGroupOrderMutationResult decodeNestedGroupOrderMutationResult(
    Object? rawResponse,
  ) {
    final item = _envelopeDecoder.decodeItemMap(
      rawResponse,
      label: 'nested group order mutation result',
    );
    if (item.keys.toSet().difference({
          'account_profile_id',
          'groups',
        }).isNotEmpty ||
        !item.keys.toSet().containsAll({'account_profile_id', 'groups'})) {
      throw const FormatException('Invalid nested group order response.');
    }
    final accountProfileId = _asString(item['account_profile_id']);
    final rawGroups = item['groups'];
    if (accountProfileId == null ||
        accountProfileId.trim().isEmpty ||
        rawGroups is! List) {
      throw const FormatException('Invalid nested group order response.');
    }

    return TenantAdminGroupOrderMutationResult(
      accountProfileIdValue: TenantAdminNestedProfileGroupTextValue(
        accountProfileId,
      ),
      groups: _decodeOrderEntries(rawGroups, 'nested group order response'),
    );
  }

  List<TenantAdminGroupOrderEntry> _decodeOrderEntries(
    List<dynamic> rawGroups,
    String label,
  ) {
    final entries = <TenantAdminGroupOrderEntry>[];
    for (final rawGroup in rawGroups) {
      if (rawGroup is! Map) throw FormatException('Invalid $label.');
      final group = Map<String, dynamic>.from(rawGroup);
      if (group.keys.toSet().difference({'id', 'order'}).isNotEmpty ||
          !group.keys.toSet().containsAll({'id', 'order'})) {
        throw FormatException('Invalid $label.');
      }
      final id = _asString(group['id']);
      final order = group['order'];
      if (id == null || id.trim().isEmpty || order is! int || order < 0) {
        throw FormatException('Invalid $label.');
      }
      entries.add(
        TenantAdminGroupOrderEntry(
          idValue: TenantAdminNestedProfileGroupTextValue(id),
          orderValue: TenantAdminNestedProfileGroupOrderValue(order),
        ),
      );
    }
    return entries;
  }

  TenantAdminProfileTypeDTO decodeProfileTypeItem(Object? rawResponse) {
    return TenantAdminProfileTypeDTO.fromJson(
      _envelopeDecoder.decodeItemMap(rawResponse, label: 'profile type'),
    );
  }

  List<TenantAdminProfileTypeDTO> decodeProfileTypeList(Object? rawResponse) {
    return _envelopeDecoder
        .decodeListMap(rawResponse, label: 'profile types')
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

  TenantAdminNestedProfileGroup? _decodeNestedProfileGroup(
    Map<String, dynamic> row, {
    bool requireCompleteNumbers = false,
  }) {
    final id = _asString(row['id']);
    final label = _asString(row['label']);
    if (id == null || label == null) {
      return null;
    }

    final order = requireCompleteNumbers
        ? _strictNonNegativeInt(row['order'])
        : _asInt(row['order']);
    final memberCount = requireCompleteNumbers
        ? _strictNonNegativeInt(row['member_count'])
        : _asInt(row['member_count']);
    if (order == null || memberCount == null) {
      return null;
    }

    return TenantAdminNestedProfileGroup(
      idValue: TenantAdminNestedProfileGroupTextValue(id),
      labelValue: TenantAdminNestedProfileGroupTextValue(label),
      orderValue: TenantAdminNestedProfileGroupOrderValue(order),
      memberCountValue: TenantAdminCountValue(memberCount),
    );
  }

  String? _asString(Object? raw) {
    if (raw is! String) {
      return null;
    }
    final normalized = raw.trim();
    if (normalized.isEmpty) {
      return null;
    }
    return normalized;
  }

  int _asInt(Object? raw) {
    if (raw is num) {
      return raw.toInt();
    }
    return int.tryParse(raw?.toString() ?? '') ?? 0;
  }

  int? _strictNonNegativeInt(Object? raw) {
    if (raw is! num || !raw.isFinite || raw != raw.truncateToDouble()) {
      return null;
    }
    final value = raw.toInt();
    return value < 0 ? null : value;
  }
}

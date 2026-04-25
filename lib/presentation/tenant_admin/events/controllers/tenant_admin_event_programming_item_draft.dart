import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_event.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_account_profile_id_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_value_parsers.dart';

class TenantAdminEventProgrammingItemDraft {
  TenantAdminEventProgrammingItemDraft({
    required TenantAdminEventProgrammingItem? existing,
  })  : time = existing?.time ?? '',
        title = existing?.title ?? '',
        selectedLocationProfileId = existing?.placeRef?.id,
        linkedProfileIds = existing?.accountProfileIds.toList(growable: true) ??
            <TenantAdminAccountProfileIdValue>[],
        linkedProfiles = existing?.linkedAccountProfiles.toList(
              growable: true,
            ) ??
            <TenantAdminAccountProfile>[];

  String time;
  String title;
  String? selectedLocationProfileId;
  final List<TenantAdminAccountProfileIdValue> linkedProfileIds;
  final List<TenantAdminAccountProfile> linkedProfiles;

  void upsertLinkedProfile(TenantAdminAccountProfile profile) {
    if (!linkedProfileIds.any((entry) => entry.value == profile.id)) {
      linkedProfileIds.add(TenantAdminAccountProfileIdValue(profile.id));
    }
    linkedProfiles.removeWhere((entry) => entry.id == profile.id);
    linkedProfiles.add(profile);
  }

  void removeLinkedProfile(String profileId) {
    linkedProfileIds.removeWhere((item) => item.value == profileId);
    linkedProfiles.removeWhere((profile) => profile.id == profileId);
  }

  List<String> availableOccurrenceProfileIds(
    List<TenantAdminAccountProfile> occurrenceRelatedProfiles,
  ) {
    return occurrenceRelatedProfiles
        .map((profile) => profile.id)
        .where(
          (profileId) => !linkedProfileIds.any(
            (selected) => selected.value == profileId,
          ),
        )
        .toList(growable: false);
  }

  String? validate() {
    final normalizedTime = time.trim();
    final normalizedTitle = title.trim();
    if (!_isValidProgrammingTime(normalizedTime)) {
      return 'Horário deve estar no formato HH:mm.';
    }
    if (normalizedTitle.isEmpty && linkedProfileIds.isEmpty) {
      return 'Informe um título ou vincule um perfil.';
    }
    if (normalizedTitle.isEmpty && linkedProfileIds.length > 1) {
      return 'Informe um título quando houver mais de um perfil vinculado.';
    }
    return null;
  }

  TenantAdminEventProgrammingItem toProgrammingItem() {
    final normalizedTitle = title.trim();
    return TenantAdminEventProgrammingItem(
      timeValue: tenantAdminRequiredText(time.trim()),
      titleValue: tenantAdminOptionalText(
        normalizedTitle.isEmpty ? null : normalizedTitle,
      ),
      accountProfileIdValues:
          List<TenantAdminAccountProfileIdValue>.unmodifiable(
        linkedProfileIds,
      ),
      linkedAccountProfiles: List<TenantAdminAccountProfile>.unmodifiable(
        linkedProfiles,
      ),
      placeRef: selectedLocationProfileId == null
          ? null
          : TenantAdminEventPlaceRef(
              typeValue: tenantAdminRequiredText('account_profile'),
              idValue: tenantAdminRequiredText(selectedLocationProfileId!),
            ),
    );
  }

  bool _isValidProgrammingTime(String value) {
    final match = RegExp(r'^([01]\d|2[0-3]):([0-5]\d)$').firstMatch(value);
    return match != null;
  }
}

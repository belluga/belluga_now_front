import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_event.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_account_profile_id_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_value_parsers.dart';

class TenantAdminEventOccurrenceEditorDraft {
  TenantAdminEventOccurrenceEditorDraft({
    required this.existing,
    required this.startAt,
    required this.endAt,
    required List<TenantAdminAccountProfileIdValue> relatedProfileIds,
    required List<TenantAdminAccountProfile> relatedProfiles,
    required List<TenantAdminEventProgrammingItem> programmingItems,
  })  : relatedProfileIds = relatedProfileIds.toList(growable: true),
        relatedProfiles = relatedProfiles.toList(growable: true),
        programmingItems = programmingItems.toList(growable: true);

  factory TenantAdminEventOccurrenceEditorDraft.fromOccurrence({
    required TenantAdminEventOccurrence? existing,
    required DateTime fallbackStart,
    required DateTime? fallbackEnd,
  }) {
    return TenantAdminEventOccurrenceEditorDraft(
      existing: existing,
      startAt: existing?.dateTimeStart ?? fallbackStart,
      endAt: existing?.dateTimeEnd ?? fallbackEnd,
      relatedProfileIds: existing?.relatedAccountProfileIds ??
          const <TenantAdminAccountProfileIdValue>[],
      relatedProfiles: existing?.relatedAccountProfiles ??
          const <TenantAdminAccountProfile>[],
      programmingItems: existing?.programmingItems ??
          const <TenantAdminEventProgrammingItem>[],
    );
  }

  final TenantAdminEventOccurrence? existing;
  DateTime startAt;
  DateTime? endAt;
  final List<TenantAdminAccountProfileIdValue> relatedProfileIds;
  final List<TenantAdminAccountProfile> relatedProfiles;
  final List<TenantAdminEventProgrammingItem> programmingItems;

  void applyStart(DateTime value) {
    startAt = value;
    if (endAt != null && endAt!.isBefore(startAt)) {
      endAt = startAt;
    }
  }

  void applyEnd(DateTime? value) {
    endAt = value;
  }

  void upsertRelatedProfile(TenantAdminAccountProfile profile) {
    if (!relatedProfileIds.any((entry) => entry.value == profile.id)) {
      relatedProfileIds.add(TenantAdminAccountProfileIdValue(profile.id));
    }
    relatedProfiles.removeWhere((entry) => entry.id == profile.id);
    relatedProfiles.add(profile);
  }

  void removeRelatedProfile(String profileId) {
    relatedProfileIds.removeWhere((entry) => entry.value == profileId);
    relatedProfiles.removeWhere((profile) => profile.id == profileId);
    for (var itemIndex = 0; itemIndex < programmingItems.length; itemIndex++) {
      programmingItems[itemIndex] = withoutProgrammingProfile(
        programmingItems[itemIndex],
        profileId,
      );
    }
  }

  void addProgrammingItem(TenantAdminEventProgrammingItem item) {
    programmingItems.add(item);
    _sortProgrammingItems();
  }

  void updateProgrammingItem(int index, TenantAdminEventProgrammingItem item) {
    if (index < 0 || index >= programmingItems.length) {
      return;
    }
    programmingItems[index] = item;
    _sortProgrammingItems();
  }

  void removeProgrammingItem(int index) {
    if (index < 0 || index >= programmingItems.length) {
      return;
    }
    programmingItems.removeAt(index);
  }

  String? validate() {
    if (endAt != null && endAt!.isBefore(startAt)) {
      return 'Fim deve ser posterior ao início.';
    }
    return null;
  }

  TenantAdminEventOccurrence toOccurrence() {
    return TenantAdminEventOccurrence(
      occurrenceIdValue: tenantAdminOptionalText(existing?.occurrenceId),
      occurrenceSlugValue: tenantAdminOptionalText(existing?.occurrenceSlug),
      dateTimeStartValue: tenantAdminDateTime(startAt),
      dateTimeEndValue: tenantAdminOptionalDateTime(endAt),
      relatedAccountProfileIdValues:
          List<TenantAdminAccountProfileIdValue>.unmodifiable(
        relatedProfileIds,
      ),
      relatedAccountProfiles: List<TenantAdminAccountProfile>.unmodifiable(
        relatedProfiles,
      ),
      programmingItems: List<TenantAdminEventProgrammingItem>.unmodifiable(
        programmingItems,
      ),
    );
  }

  void _sortProgrammingItems() {
    programmingItems.sort((left, right) => left.time.compareTo(right.time));
  }

  static TenantAdminEventProgrammingItem withoutProgrammingProfile(
    TenantAdminEventProgrammingItem item,
    String profileId,
  ) {
    return TenantAdminEventProgrammingItem(
      timeValue: tenantAdminRequiredText(item.time),
      titleValue: tenantAdminOptionalText(item.title),
      accountProfileIdValues: item.accountProfileIds
          .where((entry) => entry.value != profileId)
          .toList(growable: false),
      linkedAccountProfiles: item.linkedAccountProfiles
          .where((profile) => profile.id != profileId)
          .toList(growable: false),
      placeRef: item.placeRef,
    );
  }

  static String profileDisplayName(
    String profileId,
    List<TenantAdminAccountProfile> profiles,
  ) {
    final profile = _firstWhereOrNull(
      profiles,
      (item) => item.id == profileId,
    );
    return profile?.displayName ?? 'Perfil relacionado $profileId';
  }

  static String? firstProgrammingProfileName(
    TenantAdminEventProgrammingItem item,
  ) {
    if (item.linkedAccountProfiles.isEmpty) {
      return null;
    }
    return item.linkedAccountProfiles.first.displayName;
  }

  static String? programmingLocationDisplayName(
    TenantAdminEventProgrammingItem item,
    List<TenantAdminAccountProfile> venues,
  ) {
    final locationProfileId = item.placeRef?.id;
    if (locationProfileId == null || locationProfileId.isEmpty) {
      return null;
    }
    final venue = _firstWhereOrNull(
      venues,
      (candidate) => candidate.id == locationProfileId,
    );
    if (venue != null) {
      return venue.displayName;
    }
    final linkedProfile = _firstWhereOrNull(
      item.linkedAccountProfiles,
      (candidate) => candidate.id == locationProfileId,
    );
    return linkedProfile?.displayName ??
        'Perfil relacionado $locationProfileId';
  }

  static E? _firstWhereOrNull<E>(
    Iterable<E> values,
    bool Function(E value) matcher,
  ) {
    for (final value in values) {
      if (matcher(value)) {
        return value;
      }
    }
    return null;
  }
}

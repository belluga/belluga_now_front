import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:belluga_now/domain/partners/account_profile_summary.dart';
import 'package:belluga_now/domain/partners/value_objects/account_profile_public_detail_path_value.dart';
import 'package:belluga_now/domain/schedule/event_occurrence_option.dart';
import 'package:belluga_now/domain/schedule/event_profile_group.dart';
import 'package:belluga_now/domain/schedule/event_programming_item.dart';
import 'package:belluga_now/domain/partners/value_objects/account_profile_text_value.dart';
import 'package:belluga_now/domain/schedule/value_objects/event_occurrence_values.dart';
import 'package:belluga_now/domain/schedule/value_objects/event_tag_value.dart';
import 'package:belluga_now/domain/value_objects/domain_boolean_value.dart';
import 'package:value_object_pattern/domain/value_objects/date_time_value.dart';

class EventSelectedOccurrenceProjection {
  const EventSelectedOccurrenceProjection._();

  static EventModel align(EventModel event) {
    final occurrenceId = event.selectedOccurrenceId?.trim();
    if (occurrenceId == null || occurrenceId.isEmpty) {
      return event;
    }

    final selectedOccurrence = event.selectedOccurrence;
    if (selectedOccurrence == null) {
      return event;
    }

    final expectedEnd = _dateTimeEndForSelectedOccurrence(selectedOccurrence);
    final hasMatchingSchedule =
        _dateTimeSignature(event.dateTimeStart) ==
            _dateTimeSignature(selectedOccurrence.dateTimeStartValue) &&
        _dateTimeSignature(event.dateTimeEnd) ==
            _dateTimeSignature(expectedEnd);
    final hasMatchingProgramming =
        _programmingSignature(event.programmingItems) ==
        _programmingSignature(selectedOccurrence.programmingItems);
    final hasMatchingTags =
        _tagSignature(event.tags) == _tagSignature(selectedOccurrence.tags);
    final effectiveLinkedAccountProfiles = _selectedOccurrenceLinkedProfiles(
      event,
      selectedOccurrence,
    );
    final hasMatchingLinkedProfiles =
        _linkedAccountProfileSignature(event.linkedAccountProfiles) ==
        _linkedAccountProfileSignature(effectiveLinkedAccountProfiles);
    final effectiveProfileGroups = _selectedOccurrenceProfileGroups(
      event,
      selectedOccurrence,
      effectiveLinkedAccountProfiles,
    );
    final hasMatchingProfileGroups =
        _profileGroupSignature(event.profileGroups) ==
        _profileGroupSignature(effectiveProfileGroups);

    if (hasMatchingSchedule &&
        hasMatchingProgramming &&
        hasMatchingTags &&
        hasMatchingLinkedProfiles &&
        hasMatchingProfileGroups) {
      return event;
    }

    return project(
      event,
      occurrenceId,
      preserveCurrentProgrammingWhenAlreadySelectedAndTargetEmpty: true,
    );
  }

  static EventModel project(
    EventModel event,
    String occurrenceId, {
    bool preserveCurrentProgrammingWhenAlreadySelectedAndTargetEmpty = false,
  }) {
    final normalizedOccurrenceId = occurrenceId.trim();
    if (normalizedOccurrenceId.isEmpty) {
      return event;
    }

    EventOccurrenceOption? selectedOccurrence;
    for (final occurrence in event.occurrences) {
      if (occurrence.occurrenceId == normalizedOccurrenceId) {
        selectedOccurrence = occurrence;
        break;
      }
    }
    if (selectedOccurrence == null) {
      return event;
    }

    final preservesCurrentSelectedProgramming =
        preserveCurrentProgrammingWhenAlreadySelectedAndTargetEmpty &&
        (event.selectedOccurrenceId?.trim() ?? '') == normalizedOccurrenceId &&
        selectedOccurrence.programmingItems.isEmpty;
    final effectiveLinkedAccountProfiles = _selectedOccurrenceLinkedProfiles(
      event,
      selectedOccurrence,
    );
    final effectiveProfileGroups = _selectedOccurrenceProfileGroups(
      event,
      selectedOccurrence,
      effectiveLinkedAccountProfiles,
    );

    final updatedOccurrences = event.occurrences
        .map(
          (occurrence) => EventOccurrenceOption(
            occurrenceIdValue: occurrence.occurrenceIdValue,
            occurrenceSlugValue: occurrence.occurrenceSlugValue,
            dateTimeStartValue: occurrence.dateTimeStartValue,
            dateTimeEndValue: occurrence.dateTimeEndValue,
            isSelectedValue: EventOccurrenceFlagValue()
              ..parse(
                (occurrence.occurrenceId == normalizedOccurrenceId).toString(),
              ),
            hasLocationOverrideValue: occurrence.hasLocationOverrideValue,
            programmingCountValue: occurrence.programmingCountValue,
            linkedAccountProfiles: occurrence.linkedAccountProfiles,
            programmingItems: occurrence.programmingItems,
            profileGroups: occurrence.profileGroups,
            tags: occurrence.tags,
          ),
        )
        .toList(growable: false);

    return EventModel(
      id: event.id,
      slugValue: event.slugValue,
      type: event.type,
      title: event.title,
      content: event.content,
      location: event.location,
      venue: event.venue,
      thumb: event.thumb,
      dateTimeStart: selectedOccurrence.dateTimeStartValue,
      dateTimeEnd: _dateTimeEndForSelectedOccurrence(selectedOccurrence),
      linkedAccountProfiles: effectiveLinkedAccountProfiles,
      counterpartPreviewProfiles: event.counterpartPreviewProfiles,
      counterpartCountValue: event.counterpartCountValue,
      profileGroups: effectiveProfileGroups,
      occurrences: updatedOccurrences,
      programmingItems: preservesCurrentSelectedProgramming
          ? event.programmingItems
          : selectedOccurrence.programmingItems,
      coordinate: event.coordinate,
      tags: selectedOccurrence.tags.isNotEmpty
          ? selectedOccurrence.tags
          : event.tags,
      isConfirmedValue: event.isConfirmedValue,
      confirmedAtValue: event.confirmedAtValue,
      receivedInvites: event.receivedInvites,
      sentInvites: event.sentInvites,
      friendsGoing: event.friendsGoing,
      totalConfirmedValue: event.totalConfirmedValue,
    );
  }

  static DateTimeValue? _dateTimeEndForSelectedOccurrence(
    EventOccurrenceOption selectedOccurrence,
  ) {
    final end = selectedOccurrence.dateTimeEnd;
    if (end == null) {
      return null;
    }

    return DateTimeValue()..parse(end.toIso8601String());
  }

  static String _dateTimeSignature(DateTimeValue? value) {
    return value?.value?.toIso8601String() ?? '';
  }

  static List<AccountProfileSummary> _selectedOccurrenceLinkedProfiles(
    EventModel event,
    EventOccurrenceOption selectedOccurrence,
  ) {
    final occurrenceProfiles = selectedOccurrence.linkedAccountProfiles;
    if (occurrenceProfiles.isEmpty) {
      return event.linkedAccountProfiles;
    }

    final occurrenceById = <String, AccountProfileSummary>{
      for (final profile in occurrenceProfiles)
        if (profile.id.trim().isNotEmpty) profile.id.trim(): profile,
    };
    final seenIds = <String>{};
    final merged = <AccountProfileSummary>[];

    for (final profile in event.linkedAccountProfiles) {
      final profileId = profile.id.trim();
      if (profileId.isEmpty || !seenIds.add(profileId)) {
        continue;
      }
      final override = occurrenceById.remove(profileId);
      merged.add(
        override == null
            ? profile
            : _mergeLinkedAccountProfile(
                aggregate: profile,
                selectedOccurrence: override,
              ),
      );
    }

    for (final profile in occurrenceProfiles) {
      final profileId = profile.id.trim();
      if (profileId.isEmpty || !seenIds.add(profileId)) {
        continue;
      }
      merged.add(profile);
    }

    return List<AccountProfileSummary>.unmodifiable(merged);
  }

  static List<EventProfileGroup> _selectedOccurrenceProfileGroups(
    EventModel event,
    EventOccurrenceOption selectedOccurrence,
    List<AccountProfileSummary> linkedAccountProfiles,
  ) {
    final baseGroups = event.profileGroups.isNotEmpty
        ? event.profileGroups
        : selectedOccurrence.profileGroups;
    if (baseGroups.isEmpty) {
      return event.profileGroups;
    }

    final profilesById = <String, AccountProfileSummary>{
      for (final profile in linkedAccountProfiles)
        if (profile.id.trim().isNotEmpty) profile.id.trim(): profile,
    };

    return List<EventProfileGroup>.unmodifiable(
      baseGroups.map((group) {
        final resolvedProfiles = _resolveProfileGroupProfiles(
          group: group,
          profilesById: profilesById,
        );
        final resolvedAccountProfileIds =
            group.accountProfileIdValues.isNotEmpty
            ? group.accountProfileIdValues
            : resolvedProfiles
                  .map((profile) => profile.id.trim())
                  .where((id) => id.isNotEmpty)
                  .map(AccountProfileTextValue.new)
                  .toList(growable: false);
        return EventProfileGroup(
          idValue: group.idValue,
          labelValue: group.labelValue,
          orderValue: group.orderValue,
          membersPathValue: group.membersPathValue,
          memberCountValue: group.memberCountValue,
          profiles: resolvedProfiles,
          accountProfileIdValues: resolvedAccountProfileIds,
        );
      }),
    );
  }

  static List<AccountProfileSummary> _resolveProfileGroupProfiles({
    required EventProfileGroup group,
    required Map<String, AccountProfileSummary> profilesById,
  }) {
    final snapshotProfilesById = <String, AccountProfileSummary>{
      for (final profile in group.profiles)
        if (profile.id.trim().isNotEmpty) profile.id.trim(): profile,
    };
    final groupProfileIds = group.accountProfileIdValues
        .map((profileId) => profileId.value.trim())
        .where((id) => id.isNotEmpty)
        .toList(growable: false);
    if (groupProfileIds.isNotEmpty) {
      return List<AccountProfileSummary>.unmodifiable(
        groupProfileIds
            .map(
              (profileId) => _resolveGroupedProfile(
                profileId: profileId,
                profilesById: profilesById,
                snapshotProfilesById: snapshotProfilesById,
              ),
            )
            .whereType<AccountProfileSummary>(),
      );
    }

    final seenIds = <String>{};
    final resolvedProfiles = <AccountProfileSummary>[];
    for (final profile in group.profiles) {
      final profileId = profile.id.trim();
      if (profileId.isNotEmpty && !seenIds.add(profileId)) {
        continue;
      }
      resolvedProfiles.add(
        _resolveGroupedProfile(
              profileId: profileId,
              profilesById: profilesById,
              snapshotProfilesById: snapshotProfilesById,
            ) ??
            profile,
      );
    }
    return List<AccountProfileSummary>.unmodifiable(resolvedProfiles);
  }

  static AccountProfileSummary? _resolveGroupedProfile({
    required String profileId,
    required Map<String, AccountProfileSummary> profilesById,
    required Map<String, AccountProfileSummary> snapshotProfilesById,
  }) {
    final normalizedProfileId = profileId.trim();
    if (normalizedProfileId.isEmpty) {
      return null;
    }
    final aggregate = profilesById[normalizedProfileId];
    final snapshot = snapshotProfilesById[normalizedProfileId];
    if (aggregate != null && snapshot != null) {
      return _mergeLinkedAccountProfile(
        aggregate: aggregate,
        selectedOccurrence: snapshot,
      );
    }
    return aggregate ?? snapshot;
  }

  static String _programmingSignature(List<EventProgrammingItem> items) {
    return items
        .map((item) {
          final profileIds = item.linkedAccountProfiles
              .map((profile) => profile.id.trim())
              .where((id) => id.isNotEmpty)
              .join(',');
          return [
            item.time,
            item.endTime ?? '',
            item.title ?? '',
            profileIds,
            item.locationProfile?.id.trim() ?? '',
          ].join(':');
        })
        .join('|');
  }

  static String _profileGroupSignature(List<EventProfileGroup> groups) {
    return groups
        .map((group) {
          final profileSignature = _linkedAccountProfileSignature(
            group.profiles,
          );
          final memberIds = group.accountProfileIdValues
              .map((profileId) => profileId.value)
              .join(',');
          return [
            group.id,
            group.label,
            group.order,
            group.memberCount,
            group.membersPath?.trim() ?? '',
            memberIds,
            profileSignature,
          ].join(':');
        })
        .join('|');
  }

  static String _linkedAccountProfileSignature(
    List<AccountProfileSummary> profiles,
  ) {
    return profiles
        .map((profile) {
          final taxonomySignature = profile.taxonomyTerms
              .map(
                (term) => [
                  term.typeValue.value,
                  term.valueValue.value,
                  term.nameValue.value,
                  term.taxonomyNameValue.value,
                  term.compatibilityLabelValue.value,
                ].join('~'),
              )
              .join(',');
          return [
            profile.id.trim(),
            profile.displayName.trim(),
            profile.profileType.trim(),
            profile.partyType?.trim() ?? '',
            profile.slug.trim(),
            profile.avatarUrl?.trim() ?? '',
            profile.coverUrl?.trim() ?? '',
            profile.locationAddress?.trim() ?? '',
            profile.locationLat?.toString() ?? '',
            profile.locationLng?.toString() ?? '',
            profile.publicDetailUrl ?? '',
            taxonomySignature,
          ].join(':');
        })
        .join('|');
  }

  static AccountProfileSummary _mergeLinkedAccountProfile({
    required AccountProfileSummary aggregate,
    required AccountProfileSummary selectedOccurrence,
  }) {
    final publicDetailUrl =
        selectedOccurrence.publicDetailUrl ?? aggregate.publicDetailUrl;
    return AccountProfileSummary(
      idValue: aggregate.idValue,
      nameValue: selectedOccurrence.name.trim().isNotEmpty
          ? selectedOccurrence.nameValue
          : aggregate.nameValue,
      profileTypeValue: selectedOccurrence.profileType.trim().isNotEmpty
          ? selectedOccurrence.profileTypeValue
          : aggregate.profileTypeValue,
      partyTypeValue:
          selectedOccurrence.partyTypeValue ?? aggregate.partyTypeValue,
      slugValue: selectedOccurrence.slug.trim().isNotEmpty
          ? selectedOccurrence.slugValue
          : aggregate.slugValue,
      avatarValue: (selectedOccurrence.avatarUrl?.trim().isNotEmpty ?? false)
          ? selectedOccurrence.avatarValue
          : aggregate.avatarValue,
      coverValue: (selectedOccurrence.coverUrl?.trim().isNotEmpty ?? false)
          ? selectedOccurrence.coverValue
          : aggregate.coverValue,
      locationAddressValue:
          (selectedOccurrence.locationAddress?.trim().isNotEmpty ?? false)
          ? selectedOccurrence.locationAddressValue
          : aggregate.locationAddressValue,
      locationLatitudeValue:
          selectedOccurrence.locationLatitudeValue ??
          aggregate.locationLatitudeValue,
      locationLongitudeValue:
          selectedOccurrence.locationLongitudeValue ??
          aggregate.locationLongitudeValue,
      canOpenPublicDetailValue: DomainBooleanValue(
        defaultValue: false,
        isRequired: false,
      )..parse((publicDetailUrl != null).toString()),
      publicDetailPathValue: publicDetailUrl == null
          ? null
          : AccountProfilePublicDetailPathValue(publicDetailUrl),
      taxonomyTerms: _mergeTaxonomyTerms(
        primary: selectedOccurrence.taxonomyTerms,
        secondary: aggregate.taxonomyTerms,
      ),
    );
  }

  static AccountProfileTaxonomyTerms _mergeTaxonomyTerms({
    required AccountProfileTaxonomyTerms primary,
    required AccountProfileTaxonomyTerms secondary,
  }) {
    if (primary.isEmpty) {
      return secondary;
    }
    if (secondary.isEmpty) {
      return primary;
    }

    final merged = AccountProfileTaxonomyTerms();
    final seen = <String>{};

    void ingest(AccountProfileTaxonomyTerms source) {
      for (final term in source) {
        final key = '${term.typeValue.value}:${term.valueValue.value}';
        if (!seen.add(key)) {
          continue;
        }
        merged.addTerm(
          typeValue: term.typeValue,
          valueValue: term.valueValue,
          nameValue: term.nameValue,
          taxonomyNameValue: term.taxonomyNameValue,
          labelValue: term.compatibilityLabelValue,
        );
      }
    }

    ingest(primary);
    ingest(secondary);
    return merged;
  }

  static String _tagSignature(Iterable<dynamic> tags) {
    return tags
        .map(
          (tag) =>
              tag is EventTagValue ? tag.value.trim() : tag.toString().trim(),
        )
        .where((tag) => tag.isNotEmpty)
        .join('|');
  }
}

import 'package:belluga_now/application/schedule/event_related_profile_group_summary.dart';
import 'package:belluga_now/domain/schedule/event_linked_account_profile.dart';
import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:belluga_now/domain/schedule/event_profile_group.dart';

typedef EventRelatedProfileGroupLabelResolver = String Function(
  String profileType,
  String fallback,
);

final class EventRelatedProfileGroups {
  EventRelatedProfileGroups._();

  static List<EventRelatedProfileGroupSummary> fromEvent(
    EventModel event, {
    EventRelatedProfileGroupLabelResolver? labelResolver,
  }) {
    return fromParts(
      profileGroups: event.profileGroups,
      linkedAccountProfiles: event.linkedAccountProfiles,
      venueId: event.venue?.id,
      labelResolver: labelResolver,
    );
  }

  static List<EventRelatedProfileGroupSummary> fromAggregatedEvent(
    EventModel event, {
    EventRelatedProfileGroupLabelResolver? labelResolver,
  }) {
    return fromAggregatedParts(
      eventProfileGroups: event.profileGroups,
      occurrenceProfileGroups:
          event.occurrences.map((occurrence) => occurrence.profileGroups),
      linkedAccountProfiles: event.linkedAccountProfiles,
      venueId: event.venue?.id,
      labelResolver: labelResolver,
    );
  }

  static List<EventRelatedProfileGroupSummary> fromAggregatedParts({
    required List<EventProfileGroup> eventProfileGroups,
    required Iterable<List<EventProfileGroup>> occurrenceProfileGroups,
    required List<EventLinkedAccountProfile> linkedAccountProfiles,
    String? venueId,
    EventRelatedProfileGroupLabelResolver? labelResolver,
  }) {
    final groups = <EventProfileGroup>[
      ..._orderedGroups(eventProfileGroups),
      for (final occurrenceGroups in occurrenceProfileGroups)
        ..._orderedGroups(occurrenceGroups),
    ];

    final summaries = _mergedSummariesByGroupId(
      profileGroups: groups,
      linkedAccountProfiles: linkedAccountProfiles,
      venueId: venueId,
    );
    if (summaries.isNotEmpty) {
      return summaries;
    }

    return fromParts(
      profileGroups: const [],
      linkedAccountProfiles: linkedAccountProfiles,
      venueId: venueId,
      labelResolver: labelResolver,
    );
  }

  static List<EventRelatedProfileGroupSummary> fromParts({
    required List<EventProfileGroup> profileGroups,
    required List<EventLinkedAccountProfile> linkedAccountProfiles,
    String? venueId,
    EventRelatedProfileGroupLabelResolver? labelResolver,
  }) {
    if (profileGroups.isNotEmpty) {
      final orderedGroups = [...profileGroups]
        ..sort((left, right) => left.order.compareTo(right.order));
      final summaries = <EventRelatedProfileGroupSummary>[];
      for (final group in orderedGroups) {
        final profiles = _dedupeProfiles(
          _nonVenueProfiles(
            _profilesForGroup(group, linkedAccountProfiles),
            venueId: venueId,
          ),
        );
        if (profiles.isEmpty) {
          continue;
        }
        final label = group.label.trim();
        summaries.add(
          EventRelatedProfileGroupSummary(
            label: label.isEmpty ? 'Grupo' : label,
            profiles: profiles,
          ),
        );
      }
      return List<EventRelatedProfileGroupSummary>.unmodifiable(summaries);
    }

    final groupedProfiles = _legacyGroupedProfilesByType(
      linkedAccountProfiles: linkedAccountProfiles,
      venueId: venueId,
    );

    return groupedProfiles.entries
        .where((entry) => entry.value.isNotEmpty)
        .map((entry) {
      final fallback = _humanizeTypeKey(entry.key);
      final label = labelResolver?.call(entry.key, fallback) ?? fallback;
      return EventRelatedProfileGroupSummary(
        label: label.trim().isEmpty ? fallback : label,
        profiles: entry.value,
      );
    }).toList(growable: false);
  }

  static Map<String, List<EventLinkedAccountProfile>>
      _legacyGroupedProfilesByType({
    required List<EventLinkedAccountProfile> linkedAccountProfiles,
    String? venueId,
  }) {
    final groupedProfiles = <String, List<EventLinkedAccountProfile>>{};

    for (final profile in _nonVenueProfiles(
      linkedAccountProfiles,
      venueId: venueId,
    )) {
      final type = profile.profileType.trim();
      if (type.isEmpty) {
        continue;
      }

      final bucket = groupedProfiles.putIfAbsent(
        type,
        () => <EventLinkedAccountProfile>[],
      );
      if (bucket.any((existing) => existing.id == profile.id)) {
        continue;
      }
      bucket.add(profile);
    }

    return Map<String, List<EventLinkedAccountProfile>>.unmodifiable(
      groupedProfiles.map(
        (key, value) => MapEntry(
          key,
          List<EventLinkedAccountProfile>.unmodifiable(value),
        ),
      ),
    );
  }

  static List<EventProfileGroup> _orderedGroups(
    List<EventProfileGroup> groups,
  ) {
    return [...groups]
      ..sort((left, right) => left.order.compareTo(right.order));
  }

  static List<EventRelatedProfileGroupSummary> _mergedSummariesByGroupId({
    required List<EventProfileGroup> profileGroups,
    required List<EventLinkedAccountProfile> linkedAccountProfiles,
    String? venueId,
  }) {
    final buckets = <String, _MutableProfileGroupSummary>{};

    for (final group in profileGroups) {
      final rawLabel = group.label.trim();
      final label = rawLabel.isEmpty ? 'Grupo' : rawLabel;
      final key = label.toLowerCase();
      final profiles = _dedupeProfiles(
        _nonVenueProfiles(
          _profilesForGroup(group, linkedAccountProfiles),
          venueId: venueId,
        ),
      );
      if (profiles.isEmpty) {
        continue;
      }

      final groupId = group.id.trim();
      final bucket = buckets.putIfAbsent(
        groupId.isEmpty ? key : groupId,
        () => _MutableProfileGroupSummary(label, group.order),
      );
      if (group.order < bucket.order) {
        bucket.order = group.order;
      }
      bucket.addAll(profiles);
    }

    final orderedBuckets = buckets.values.toList(growable: false)
      ..sort((left, right) => left.order.compareTo(right.order));

    return orderedBuckets
        .map(
          (bucket) => EventRelatedProfileGroupSummary(
            label: bucket.label,
            profiles: bucket.profiles,
          ),
        )
        .toList(growable: false);
  }

  static List<EventLinkedAccountProfile> _profilesForGroup(
    EventProfileGroup group,
    List<EventLinkedAccountProfile> linkedAccountProfiles,
  ) {
    if (group.profiles.isNotEmpty || group.accountProfileIdValues.isEmpty) {
      return group.profiles;
    }

    final profilesById = <String, EventLinkedAccountProfile>{
      for (final profile in linkedAccountProfiles)
        if (profile.id.trim().isNotEmpty) profile.id.trim(): profile,
    };
    return group.accountProfileIdValues
        .map((profileId) => profilesById[profileId.value])
        .whereType<EventLinkedAccountProfile>()
        .toList(growable: false);
  }

  static String _humanizeTypeKey(String raw) {
    final normalized = raw.trim().replaceAll(RegExp(r'[_-]+'), ' ');
    if (normalized.isEmpty) {
      return raw;
    }
    return normalized
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map(
          (part) =>
              '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
        )
        .join(' ');
  }

  static List<EventLinkedAccountProfile> _nonVenueProfiles(
    List<EventLinkedAccountProfile> profiles, {
    String? venueId,
  }) {
    final normalizedVenueId = venueId?.trim();
    return profiles.where((profile) {
      if (normalizedVenueId != null &&
          normalizedVenueId.isNotEmpty &&
          profile.id == normalizedVenueId) {
        return false;
      }

      final normalizedPartyType = profile.partyType?.trim().toLowerCase();
      final normalizedProfileType = profile.profileType.trim().toLowerCase();
      return normalizedPartyType != 'venue' && normalizedProfileType != 'venue';
    }).toList(growable: false);
  }

  static List<EventLinkedAccountProfile> _dedupeProfiles(
    List<EventLinkedAccountProfile> profiles,
  ) {
    final seenIds = <String>{};
    final deduped = <EventLinkedAccountProfile>[];
    for (final profile in profiles) {
      final id = profile.id.trim();
      final identity = id.isEmpty ? profile.displayName.trim() : id;
      if (identity.isEmpty || !seenIds.add(identity)) {
        continue;
      }
      deduped.add(profile);
    }
    return deduped;
  }
}

final class _MutableProfileGroupSummary {
  _MutableProfileGroupSummary(this.label, this.order);

  final String label;
  int order;
  final List<EventLinkedAccountProfile> _profiles = [];
  final Set<String> _seenProfileKeys = {};

  List<EventLinkedAccountProfile> get profiles =>
      List<EventLinkedAccountProfile>.unmodifiable(_profiles);

  void addAll(List<EventLinkedAccountProfile> profiles) {
    for (final profile in profiles) {
      final id = profile.id.trim();
      final identity = id.isEmpty ? profile.displayName.trim() : id;
      if (identity.isEmpty || !_seenProfileKeys.add(identity)) {
        continue;
      }
      _profiles.add(profile);
    }
  }
}

import 'package:belluga_now/domain/partners/value_objects/account_profile_type_value.dart';
import 'package:belluga_now/domain/schedule/event_linked_account_profile.dart';
import 'package:belluga_now/domain/schedule/event_profile_group.dart';
import 'package:belluga_now/application/schedule/event_related_profile_groups.dart';
import 'package:belluga_now/domain/schedule/value_objects/event_linked_account_profile_text_value.dart';
import 'package:belluga_now/domain/schedule/value_objects/event_profile_group_order_value.dart';
import 'package:belluga_now/domain/value_objects/slug_value.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('custom profile groups define tab/share labels and member order', () {
    final band = _profile(
      id: 'band-1',
      displayName: 'Du Jorge',
      profileType: 'band',
    );
    final exhibitor = _profile(
      id: 'expo-1',
      displayName: 'Agro Sul',
      profileType: 'producer',
    );

    final groups = EventRelatedProfileGroups.fromParts(
      profileGroups: [
        _group(label: 'Bandas', order: 1, profiles: [band]),
        _group(label: 'Expositores', profiles: [exhibitor]),
      ],
      linkedAccountProfiles: [band, exhibitor],
    );

    expect(groups.map((group) => group.label), ['Expositores', 'Bandas']);
    expect(groups.first.profileNames, ['Agro Sul']);
    expect(groups.last.profileNames, ['Du Jorge']);
  });

  test('legacy fallback groups by type and excludes venue profiles', () {
    final venue = _profile(
      id: 'venue-1',
      displayName: 'Sesc Guarapari',
      profileType: 'venue',
      partyType: 'venue',
    );
    final band = _profile(
      id: 'band-1',
      displayName: 'Du Jorge',
      profileType: 'band',
    );
    final artist = _profile(
      id: 'artist-1',
      displayName: 'Lua Norte',
      profileType: 'artist',
    );

    final groups = EventRelatedProfileGroups.fromParts(
      profileGroups: const [],
      linkedAccountProfiles: [venue, band, artist],
      venueId: 'venue-1',
      labelResolver: (type, fallback) => '$fallback públicos',
    );

    expect(groups.map((group) => group.label), [
      'Band públicos',
      'Artist públicos',
    ]);
    expect(groups.expand((group) => group.profileNames), [
      'Du Jorge',
      'Lua Norte',
    ]);
  });

  test(
      'aggregated groups combine participants from all occurrences without depending on selected occurrence group',
      () {
    final band = _profile(
      id: 'band-1',
      displayName: 'Du Jorge',
      profileType: 'band',
    );
    final secondBand = _profile(
      id: 'band-2',
      displayName: 'Banda Norte',
      profileType: 'band',
    );
    final exhibitor = _profile(
      id: 'expo-1',
      displayName: 'Agro Sul',
      profileType: 'producer',
    );

    final groups = EventRelatedProfileGroups.fromAggregatedParts(
      eventProfileGroups: [
        _group(
          label: 'Bandas',
          profiles: [band],
        ),
      ],
      occurrenceProfileGroups: [
        [
          _group(
            label: 'Bandas',
            profiles: [band],
          ),
        ],
        [
          _group(
            label: 'Bandas',
            profiles: [secondBand],
          ),
          _group(
            label: 'Expositores',
            profiles: [exhibitor],
          ),
        ],
      ],
      linkedAccountProfiles: [band, secondBand, exhibitor],
    );

    expect(groups.map((group) => group.label), ['Bandas', 'Expositores']);
    expect(groups.first.profileNames, ['Du Jorge', 'Banda Norte']);
    expect(groups.last.profileNames, ['Agro Sul']);
  });

  test('aggregated groups resolve occurrence member ids from linked profiles',
      () {
    final band = _profile(
      id: 'band-1',
      displayName: 'Du Jorge',
      profileType: 'band',
    );
    final exhibitor = _profile(
      id: 'expo-1',
      displayName: 'Agro Sul',
      profileType: 'producer',
    );

    final groups = EventRelatedProfileGroups.fromAggregatedParts(
      eventProfileGroups: const [],
      occurrenceProfileGroups: [
        [
          _group(
            label: 'Bandas',
            accountProfileIds: ['band-1'],
          ),
        ],
        [
          _group(
            label: 'Expositores',
            accountProfileIds: ['expo-1'],
          ),
        ],
      ],
      linkedAccountProfiles: [band, exhibitor],
    );

    expect(groups.map((group) => group.label), ['Bandas', 'Expositores']);
    expect(groups.first.profileNames, ['Du Jorge']);
    expect(groups.last.profileNames, ['Agro Sul']);
  });

  test(
      'aggregated groups keep event-level members first when labels overlap with occurrences',
      () {
    final eventBand = _profile(
      id: 'band-event',
      displayName: 'Banda da Capa',
      profileType: 'band',
    );
    final occurrenceBand = _profile(
      id: 'band-occurrence',
      displayName: 'Banda Convidada',
      profileType: 'band',
    );

    final groups = EventRelatedProfileGroups.fromAggregatedParts(
      eventProfileGroups: [
        _group(
          label: 'Bandas',
          profiles: [eventBand],
        ),
      ],
      occurrenceProfileGroups: [
        [
          _group(
            label: 'Bandas',
            profiles: [occurrenceBand],
          ),
        ],
      ],
      linkedAccountProfiles: [eventBand, occurrenceBand],
    );

    expect(groups.map((group) => group.label), ['Bandas']);
    expect(groups.single.profileNames, ['Banda da Capa', 'Banda Convidada']);
  });

  test(
      'aggregated groups sort merged labels by the lowest effective order across event and occurrences',
      () {
    final band = _profile(
      id: 'band-1',
      displayName: 'Du Jorge',
      profileType: 'band',
    );
    final exhibitor = _profile(
      id: 'expo-1',
      displayName: 'Agro Sul',
      profileType: 'producer',
    );

    final groups = EventRelatedProfileGroups.fromAggregatedParts(
      eventProfileGroups: [
        _group(
          label: 'Bandas',
          order: 5,
          profiles: [band],
        ),
      ],
      occurrenceProfileGroups: [
        [
          _group(
            label: 'Expositores',
            order: 1,
            profiles: [exhibitor],
          ),
        ],
      ],
      linkedAccountProfiles: [band, exhibitor],
    );

    expect(groups.map((group) => group.label), ['Expositores', 'Bandas']);
  });

  test(
      'aggregated groups keep distinct groups when labels match but ids differ',
      () {
    final firstBand = _profile(
      id: 'band-1',
      displayName: 'Du Jorge',
      profileType: 'band',
    );
    final secondBand = _profile(
      id: 'band-2',
      displayName: 'Banda Norte',
      profileType: 'band',
    );

    final groups = EventRelatedProfileGroups.fromAggregatedParts(
      eventProfileGroups: [
        _group(
          id: 'bandas-evento',
          label: 'Bandas',
          profiles: [firstBand],
        ),
      ],
      occurrenceProfileGroups: [
        [
          _group(
            id: 'bandas-data',
            label: 'Bandas',
            profiles: [secondBand],
          ),
        ],
      ],
      linkedAccountProfiles: [firstBand, secondBand],
    );

    expect(groups, hasLength(2));
    expect(groups.map((group) => group.label), ['Bandas', 'Bandas']);
    expect(groups.first.profileNames, ['Du Jorge']);
    expect(groups.last.profileNames, ['Banda Norte']);
  });

  test(
      'aggregated groups merge members by canonical group id even if labels drift',
      () {
    final band = _profile(
      id: 'band-1',
      displayName: 'Du Jorge',
      profileType: 'band',
    );
    final exhibitor = _profile(
      id: 'expo-1',
      displayName: 'Agro Sul',
      profileType: 'producer',
    );

    final groups = EventRelatedProfileGroups.fromAggregatedParts(
      eventProfileGroups: [
        _group(
          id: 'lineup',
          label: 'Bandas',
          profiles: [band],
        ),
      ],
      occurrenceProfileGroups: [
        [
          _group(
            id: 'lineup',
            label: 'Atrações',
            profiles: [exhibitor],
          ),
        ],
      ],
      linkedAccountProfiles: [band, exhibitor],
    );

    expect(groups, hasLength(1));
    expect(groups.single.label, 'Bandas');
    expect(groups.single.profileNames, ['Du Jorge', 'Agro Sul']);
  });
}

EventProfileGroup _group({
  String? id,
  required String label,
  int order = 0,
  List<EventLinkedAccountProfile> profiles = const [],
  List<String> accountProfileIds = const [],
}) {
  return EventProfileGroup(
    idValue: EventLinkedAccountProfileTextValue(id ?? 'group-$label'),
    labelValue: EventLinkedAccountProfileTextValue(label),
    orderValue: EventProfileGroupOrderValue(order),
    profiles: profiles,
    accountProfileIdValues:
        accountProfileIds.map(EventLinkedAccountProfileTextValue.new).toList(),
  );
}

EventLinkedAccountProfile _profile({
  required String id,
  required String displayName,
  required String profileType,
  String? partyType,
}) {
  return EventLinkedAccountProfile(
    idValue: EventLinkedAccountProfileTextValue(id),
    displayNameValue: EventLinkedAccountProfileTextValue(displayName),
    profileTypeValue: AccountProfileTypeValue(profileType),
    slugValue: SlugValue()..parse(id),
    partyTypeValue: partyType == null
        ? null
        : EventLinkedAccountProfileTextValue(partyType),
  );
}

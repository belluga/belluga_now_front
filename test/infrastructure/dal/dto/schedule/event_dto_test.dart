import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/infrastructure/dal/dto/schedule/event_dto.dart';
import 'package:belluga_now/testing/app_data_test_factory.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

void main() {
  setUp(() async {
    await GetIt.I.reset();
    GetIt.I.registerSingleton<AppData>(_buildAppData());
  });

  tearDown(() async {
    await GetIt.I.reset();
  });

  test('parses agenda occurrence payload shape without throwing', () {
    final dto = EventDTO.fromJson({
      'event_id': '507f1f77bcf86cd799439011',
      'occurrence_id': 'occ-1',
      'slug': 'rock-night-occ-1',
      'title': 'Rock Night',
      'content': 'Live concert',
      'type': {
        'id': 'type-1',
        'name': 'Show',
        'slug': 'show',
        'description': 'Show type',
        'icon': null,
        'color': '#112233',
      },
      'location': {
        'mode': 'physical',
        'geo': {
          'type': 'Point',
          'coordinates': [-40.1, -20.2],
        },
      },
      'venue': {
        'id': '507f1f77bcf86cd799439012',
        'display_name': 'Arena Central',
        'slug': 'arena-central',
      },
      'latitude': -20.2,
      'longitude': -40.1,
      'date_time_start': '2026-03-03T20:00:00+00:00',
      'date_time_end': '2026-03-03T22:00:00+00:00',
      'linked_account_profiles': [
        {
          'id': 'artist-1',
          'display_name': 'The Band',
          'slug': 'the-band',
          'profile_type': 'artist',
        },
      ],
      'tags': ['legacy-ignored'],
      'taxonomy_terms': [
        {'type': 'genre', 'value': 'music', 'name': 'Music'},
      ],
    });
    final domain = dto.toDomain();

    expect(dto.id, '507f1f77bcf86cd799439011');
    expect(dto.slug, 'rock-night-occ-1');
    expect(dto.title, 'Rock Night');
    expect(dto.location, 'Arena Central');
    expect(dto.dateTimeStart, '2026-03-03T20:00:00+00:00');
    expect(dto.dateTimeEnd, '2026-03-03T22:00:00+00:00');
    expect(dto.linkedAccountProfiles, hasLength(1));
    expect(dto.type.id, 'type-1');
    expect(domain.taxonomyTags.map((tag) => tag.value).toList(), ['Music']);
    expect(dto.toJson(), isNot(contains('tags')));
    expect(
      dto.toJson()['taxonomy_terms'],
      [
        {'type': 'genre', 'value': 'music', 'name': 'Music'},
      ],
    );
  });

  test('uses occurrence_id as fallback id when event_id is missing', () {
    final dto = EventDTO.fromJson({
      'occurrence_id': 'occ-42',
      'slug': 'event-occ-42',
      'type': {
        'id': 'type-1',
        'name': 'Workshop',
        'slug': 'workshop',
        'description': '',
      },
      'title': 'Occurrence only',
      'content': '',
      'location': 'Remote',
      'date_time_start': '2026-03-03T10:00:00+00:00',
      'linked_account_profiles': const [],
    });

    expect(dto.id, 'occ-42');
  });

  test('ignores legacy raw tags when canonical taxonomy_terms are absent', () {
    final dto = EventDTO.fromJson({
      'event_id': '507f1f77bcf86cd799439099',
      'slug': 'legacy-event',
      'type': {
        'id': 'type-1',
        'name': 'Show',
        'slug': 'show',
        'description': '',
      },
      'title': 'Legacy Event',
      'content': '',
      'location': 'Guarapari',
      'date_time_start': '2026-03-03T10:00:00+00:00',
      'tags': ['legacy-only'],
    });

    expect(dto.toDomain().taxonomyTags, isEmpty);
  });

  test('parses public profile groups for custom dynamic event tabs', () {
    final dto = EventDTO.fromJson({
      'event_id': '507f1f77bcf86cd799439022',
      'slug': 'evt-groups',
      'type': {
        'id': 'type-1',
        'name': 'Feira',
        'slug': 'feira',
        'description': '',
      },
      'title': 'Evento com grupos',
      'content': '',
      'location': 'Guarapari',
      'date_time_start': '2026-03-03T10:00:00+00:00',
      'linked_account_profiles': [
        {
          'id': 'artist-1',
          'display_name': 'Artista A',
          'slug': 'artista-a',
          'profile_type': 'artist',
        },
        {
          'id': 'producer-1',
          'display_name': 'Produtor B',
          'slug': 'produtor-b',
          'profile_type': 'producer',
        },
      ],
      'profile_groups': [
        {
          'id': 'expositores',
          'label': 'Expositores',
          'order': 1,
          'profiles': [
            {
              'id': 'producer-1',
              'display_name': 'Produtor B',
              'slug': 'produtor-b',
              'profile_type': 'producer',
            },
          ],
        },
        {
          'id': 'atracoes',
          'label': 'Atrações',
          'order': 0,
          'profiles': [
            {
              'id': 'artist-1',
              'display_name': 'Artista A',
              'slug': 'artista-a',
              'profile_type': 'artist',
            },
          ],
        },
      ],
    });

    final domain = dto.toDomain();

    expect(domain.profileGroups, hasLength(2));
    expect(domain.profileGroups[0].id, 'atracoes');
    expect(domain.profileGroups[0].label, 'Atrações');
    expect(domain.profileGroups[0].profiles.single.displayName, 'Artista A');
    expect(domain.profileGroups[1].id, 'expositores');
    expect(domain.profileGroups[1].profiles.single.profileType, 'producer');
  });

  test('parses linked profile navigation contract without requiring slug', () {
    final dto = EventDTO.fromJson({
      'event_id': '507f1f77bcf86cd799439055',
      'slug': 'evt-navigation-contract',
      'type': {
        'id': 'type-1',
        'name': 'Feira',
        'slug': 'feira',
        'description': '',
      },
      'title': 'Evento navegacao',
      'content': '',
      'location': 'Guarapari',
      'date_time_start': '2026-03-03T10:00:00+00:00',
      'linked_account_profiles': [
        {
          'id': 'profile-clickable',
          'display_name': 'Perfil clicável',
          'profile_type': 'artist',
          'slug': 'perfil-clicavel',
          'can_open_public_detail': true,
          'public_detail_path': '/parceiro/perfil-clicavel',
        },
        {
          'id': 'profile-static',
          'display_name': 'Perfil estático',
          'profile_type': 'artist',
          'can_open_public_detail': false,
        },
      ],
    });

    final clickable = dto.linkedAccountProfiles.first;
    final staticProfile = dto.linkedAccountProfiles.last;

    expect(clickable.canOpenPublicDetail, isTrue);
    expect(clickable.publicDetailPath, '/parceiro/perfil-clicavel');
    expect(clickable.slug, 'perfil-clicavel');
    expect(staticProfile.canOpenPublicDetail, isFalse);
    expect(staticProfile.publicDetailPath, isNull);
    expect(staticProfile.slug, isEmpty);
  });

  test(
      'normalizes relative linked profile media urls to the current tenant origin',
      () {
    final dto = EventDTO.fromJson({
      'event_id': '507f1f77bcf86cd799439155',
      'slug': 'evt-relative-linked-media',
      'type': {
        'id': 'type-1',
        'name': 'Feira',
        'slug': 'feira',
        'description': '',
      },
      'title': 'Evento com midia relativa',
      'content': '',
      'location': 'Guarapari',
      'date_time_start': '2026-03-03T10:00:00+00:00',
      'linked_account_profiles': [
        {
          'id': 'profile-relative',
          'display_name': 'Perfil relativo',
          'profile_type': 'artist',
          'avatar_url':
              '/api/v1/media/account-profiles/profile-relative/avatar?v=7',
          'cover_url': 'account-profiles/profile-relative/cover?v=8',
        },
      ],
      'profile_groups': [
        {
          'id': 'artists',
          'label': 'Artists',
          'order': 0,
          'profiles': [
            {
              'id': 'profile-relative',
              'display_name': 'Perfil relativo',
              'profile_type': 'artist',
              'avatar_url':
                  '/api/v1/media/account-profiles/profile-relative/avatar?v=7',
              'cover_url': 'account-profiles/profile-relative/cover?v=8',
            },
          ],
        },
      ],
    });

    final linkedProfile = dto.linkedAccountProfiles.single;
    final groupedProfile = dto.profileGroups.single.profiles.single;

    expect(
      linkedProfile.avatarUrl,
      'https://tenant.test/api/v1/media/account-profiles/profile-relative/avatar?v=7',
    );
    expect(
      linkedProfile.coverUrl,
      'https://tenant.test/account-profiles/profile-relative/cover?v=8',
    );
    expect(groupedProfile.avatarUrl, linkedProfile.avatarUrl);
    expect(groupedProfile.coverUrl, linkedProfile.coverUrl);
  });

  test('parses venue navigation contract from explicit public detail fields',
      () {
    final dto = EventDTO.fromJson({
      'event_id': '507f1f77bcf86cd799439056',
      'slug': 'evt-venue-navigation-contract',
      'type': {
        'id': 'type-1',
        'name': 'Feira',
        'slug': 'feira',
        'description': '',
      },
      'title': 'Evento venue navegavel',
      'content': '',
      'location': 'Guarapari',
      'venue': {
        'id': '507f1f77bcf86cd799439057',
        'display_name': 'Venue navegavel',
        'slug': 'venue-navegavel',
        'can_open_public_detail': true,
        'public_detail_path': '/parceiro/venue-navegavel',
      },
      'date_time_start': '2026-03-03T10:00:00+00:00',
    });

    final venue = dto.toDomain().venue;

    expect(venue, isNotNull);
    expect(venue?.canOpenPublicDetail, isTrue);
    expect(venue?.publicDetailPath, '/parceiro/venue-navegavel');
    expect(venue?.slug, 'venue-navegavel');
  });

  test('keeps venue non-navigable when only slug is present without path', () {
    final dto = EventDTO.fromJson({
      'event_id': '507f1f77bcf86cd799439058',
      'slug': 'evt-venue-slug-only',
      'type': {
        'id': 'type-1',
        'name': 'Feira',
        'slug': 'feira',
        'description': '',
      },
      'title': 'Evento venue slug only',
      'content': '',
      'location': 'Guarapari',
      'venue': {
        'id': '507f1f77bcf86cd799439059',
        'display_name': 'Venue sem path',
        'slug': 'venue-sem-path',
        'can_open_public_detail': true,
      },
      'date_time_start': '2026-03-03T10:00:00+00:00',
    });

    final venue = dto.toDomain().venue;

    expect(venue, isNotNull);
    expect(venue?.canOpenPublicDetail, isFalse);
    expect(venue?.publicDetailPath, isNull);
  });

  test(
      'parses occurrence profile groups with member ids for occurrence switches',
      () {
    final dto = EventDTO.fromJson({
      'event_id': '507f1f77bcf86cd799439091',
      'occurrence_id': '507f1f77bcf86cd799439092',
      'slug': 'festival-com-ocorrencias',
      'type': {
        'id': 'show',
        'name': 'Show',
        'slug': 'show',
        'description': '',
      },
      'title': 'Festival com Ocorrencias',
      'content': 'Descricao',
      'location': 'Praca Central',
      'date_time_start': '2026-03-04T17:00:00+00:00',
      'linked_account_profiles': [
        {
          'id': 'profile-band',
          'display_name': 'Banda Azul',
          'slug': 'banda-azul',
          'profile_type': 'banda',
        },
        {
          'id': 'profile-exhibitor',
          'display_name': 'Expositor Sol',
          'slug': 'expositor-sol',
          'profile_type': 'expositor',
        },
      ],
      'profile_groups': [
        {
          'id': 'palco-bandas',
          'label': 'Palco Bandas',
          'order': 0,
          'profiles': [
            {
              'id': 'profile-band',
              'display_name': 'Banda Azul',
              'slug': 'banda-azul',
              'profile_type': 'banda',
            },
          ],
        },
      ],
      'occurrences': [
        {
          'occurrence_id': '507f1f77bcf86cd799439092',
          'date_time_start': '2026-03-04T17:00:00+00:00',
          'is_selected': true,
          'profile_groups': [
            {
              'id': 'palco-bandas',
              'label': 'Palco Bandas',
              'order': 0,
              'account_profile_ids': ['profile-band'],
            },
          ],
        },
        {
          'occurrence_id': '507f1f77bcf86cd799439093',
          'date_time_start': '2026-03-05T17:00:00+00:00',
          'is_selected': false,
          'profile_groups': [
            {
              'id': 'vila-expositores',
              'label': 'Vila Expositores',
              'order': 0,
              'account_profile_ids': ['profile-exhibitor'],
            },
          ],
        },
      ],
    });

    final domain = dto.toDomain();

    expect(domain.occurrences, hasLength(2));
    expect(domain.occurrences.first.profileGroups.single.label, 'Palco Bandas');
    expect(
      domain.occurrences.first.profileGroups.single.accountProfileIdValues
          .map((id) => id.value),
      ['profile-band'],
    );
    expect(
        domain.occurrences.last.profileGroups.single.label, 'Vila Expositores');
    expect(domain.occurrences.last.profileGroups.single.profiles.single.id,
        'profile-exhibitor');
    expect(
      domain.occurrences.last.profileGroups.single.accountProfileIdValues
          .map((id) => id.value),
      ['profile-exhibitor'],
    );
  });

  test('hydrates top-level profile groups from member ids and linked profiles',
      () {
    final dto = EventDTO.fromJson({
      'event_id': '507f1f77bcf86cd799439101',
      'occurrence_id': '507f1f77bcf86cd799439102',
      'slug': 'festival-com-grupos-por-id',
      'type': {
        'id': 'festival',
        'name': 'Festival',
        'slug': 'festival',
        'description': '',
      },
      'title': 'Festival com Grupos por Id',
      'content': 'Descricao',
      'location': 'Praca Central',
      'date_time_start': '2026-03-04T17:00:00+00:00',
      'linked_account_profiles': [
        {
          'id': 'profile-band',
          'display_name': 'Banda Azul',
          'slug': 'banda-azul',
          'profile_type': 'banda',
        },
        {
          'id': 'profile-exhibitor',
          'display_name': 'Expositor Sol',
          'slug': 'expositor-sol',
          'profile_type': 'expositor',
        },
      ],
      'profile_groups': [
        {
          'id': 'palco-bandas',
          'label': 'Palco Bandas',
          'order': 0,
          'account_profile_ids': ['profile-band'],
        },
        {
          'id': 'vila-expositores',
          'label': 'Vila Expositores',
          'order': 1,
          'account_profile_ids': ['profile-exhibitor'],
        },
      ],
      'occurrences': [
        {
          'occurrence_id': '507f1f77bcf86cd799439102',
          'date_time_start': '2026-03-04T17:00:00+00:00',
          'is_selected': true,
        },
      ],
    });

    final domain = dto.toDomain();

    expect(domain.profileGroups, hasLength(2));
    expect(domain.profileGroups.first.label, 'Palco Bandas');
    expect(
        domain.profileGroups.first.profiles.single.displayName, 'Banda Azul');
    expect(domain.profileGroups.last.label, 'Vila Expositores');
    expect(
        domain.profileGroups.last.profiles.single.displayName, 'Expositor Sol');
  });

  test(
      'hydrates occurrence profile groups from occurrence-owned linked profiles when root aggregate is incomplete',
      () {
    final dto = EventDTO.fromJson({
      'event_id': '507f1f77bcf86cd799439191',
      'occurrence_id': '507f1f77bcf86cd799439192',
      'slug': 'festival-com-perfis-locais',
      'type': {
        'id': 'festival',
        'name': 'Festival',
        'slug': 'festival',
        'description': '',
      },
      'title': 'Festival com Perfis Locais',
      'content': 'Descricao',
      'location': 'Praca Central',
      'date_time_start': '2026-03-04T17:00:00+00:00',
      'linked_account_profiles': [
        {
          'id': 'profile-band',
          'display_name': 'Banda Azul',
          'slug': 'banda-azul',
          'profile_type': 'banda',
        },
      ],
      'occurrences': [
        {
          'occurrence_id': '507f1f77bcf86cd799439192',
          'date_time_start': '2026-03-04T17:00:00+00:00',
          'is_selected': true,
          'own_linked_account_profiles': [
            {
              'id': 'profile-exhibitor',
              'display_name': 'Expositor Sol',
              'slug': 'expositor-sol',
              'profile_type': 'expositor',
            },
          ],
          'profile_groups': [
            {
              'id': 'vila-expositores',
              'label': 'Vila Expositores',
              'order': 0,
              'account_profile_ids': ['profile-exhibitor'],
            },
          ],
        },
      ],
    });

    final domain = dto.toDomain();

    expect(domain.occurrences, hasLength(1));
    expect(domain.occurrences.single.profileGroups, hasLength(1));
    expect(domain.occurrences.single.profileGroups.single.label,
        'Vila Expositores');
    expect(
      domain
          .occurrences.single.profileGroups.single.profiles.single.displayName,
      'Expositor Sol',
    );
  });

  test('preserves sanitized rich html content for public event rendering', () {
    final dto = EventDTO.fromJson({
      'event_id': '507f1f77bcf86cd799439011',
      'slug': 'evt-rich',
      'type': {
        'id': 'show',
        'name': 'Show',
        'slug': 'show',
        'description': '',
      },
      'title': 'Evento com HTML rico',
      'content': '<h2>Event Rich Heading 🎉</h2>'
          '<p><strong>Bold event</strong><br />Second event line</p>'
          '<p><em>Italic event</em> and <s>strike event</s></p>'
          '<blockquote>Event quote</blockquote>'
          '<ul><li>Event bullet</li></ul>'
          '<ol><li>Event ordered</li></ol>',
      'location': 'Carvoeiro',
      'date_time_start': '2026-03-03T10:00:00+00:00',
      'linked_account_profiles': const [],
    });

    final domain = dto.toDomain();

    expect(domain.content.value, contains('<h2>Event Rich Heading 🎉</h2>'));
    expect(domain.content.value, contains('<strong>Bold event</strong>'));
    expect(domain.content.value, contains('<br'));
    expect(domain.content.value, contains('<em>Italic event</em>'));
    expect(domain.content.value, contains('<s>strike event</s>'));
    expect(
      domain.content.value,
      contains('<blockquote>Event quote</blockquote>'),
    );
    expect(domain.content.value, contains('<ul><li>Event bullet</li></ul>'));
    expect(domain.content.value, contains('<ol><li>Event ordered</li></ol>'));
    expect(domain.content.valueText, contains('Event Rich Heading 🎉'));
  });

  test(
      'derives latitude and longitude from location.geo when root keys are absent',
      () {
    final dto = EventDTO.fromJson({
      'event_id': 'evt-geo',
      'slug': 'evt-geo',
      'type': {
        'id': 'music-show',
        'name': 'Show',
        'slug': 'show',
        'description': '',
      },
      'title': 'Geo Event',
      'content': 'Geo Content',
      'location': {
        'mode': 'physical',
        'geo': {
          'type': 'Point',
          'coordinates': [-40.495395, -20.671339],
        },
      },
      'date_time_start': '2026-03-03T10:00:00+00:00',
      'linked_account_profiles': const [],
    });

    expect(dto.latitude, closeTo(-20.671339, 0.000001));
    expect(dto.longitude, closeTo(-40.495395, 0.000001));
  });

  test('maps live_now agenda payload shape from production-compatible contract',
      () {
    final dto = EventDTO.fromJson({
      'event_id': '69a77aa3680219d56909080f',
      'occurrence_id': '69a77aa3680219d569090810',
      'slug': 'karaoke',
      'type': {
        'id': '69aac4ddd37046e0fe017c86',
        'name': 'Feira',
        'slug': 'feira',
        'description': 'Feira comercial',
        'icon': null,
        'color': null,
        'icon_color': null,
      },
      'title': 'Karaokê',
      'content': 'Evento de karaokê pra você cantar.',
      'location': {
        'mode': 'physical',
        'geo': {
          'type': 'Point',
          'coordinates': [-40.498859, -20.673704],
        },
      },
      'place_ref': {
        'type': 'account_profile',
        'metadata': {'display_name': 'Carvoeiro'},
        'id': '69c558629b497835b900ac86',
      },
      'venue': {
        'id': '69c558629b497835b900ac86',
        'display_name': 'Carvoeiro',
        'slug': 'carvoeiro',
        'tagline': null,
        'hero_image_url': null,
        'logo_url': null,
      },
      'latitude': -20.673704,
      'longitude': -40.498859,
      'thumb': null,
      'date_time_start': '2026-03-29T01:00:00+00:00',
      'date_time_end': null,
      'linked_account_profiles': [
        {
          'id': '69949486be6cd999250a2507',
          'display_name': 'Ananda Torres',
          'slug': 'ananda-torres',
          'profile_type': 'artist',
          'avatar_url':
              'https://guarappari.belluga.space/account-profiles/69949486be6cd999250a2507/avatar?v=1771359996',
          'highlight': false,
          'genres': ['brasilidades', 'samba'],
        },
      ],
      'tags': const [],
      'taxonomy_terms': [
        {'type': 'genre', 'value': 'brasilidades'},
        {'type': 'genre', 'value': 'rock'},
      ],
    });

    final domain = dto.toDomain();

    expect(dto.id, '69a77aa3680219d56909080f');
    expect(dto.location, 'Carvoeiro');
    expect(dto.latitude, closeTo(-20.673704, 0.000001));
    expect(dto.longitude, closeTo(-40.498859, 0.000001));
    expect(dto.linkedAccountProfiles, hasLength(1));
    expect(domain.slug, 'karaoke');
    expect(domain.title.value, 'Karaokê');
    expect(domain.location.value, 'Carvoeiro');
    expect(domain.coordinate, isNotNull);
    expect(
      domain.linkedAccountProfiles.first.displayName,
      'Ananda Torres',
    );
  });

  test('parses linked account profiles with taxonomy names for dynamic tabs',
      () {
    final dto = EventDTO.fromJson({
      'event_id': '69a77aa3680219d56909080f',
      'slug': 'evt-linked',
      'type': {
        'id': '69a77aa3680219d569090810',
        'name': 'Show',
        'slug': 'show',
        'description': '',
      },
      'title': 'Evento com perfis',
      'content': 'Descricao',
      'location': 'Carvoeiro',
      'date_time_start': '2026-03-03T10:00:00+00:00',
      'linked_account_profiles': [
        {
          'id': 'artist-1',
          'display_name': 'Ananda Torres',
          'slug': 'ananda-torres',
          'profile_type': 'artist',
          'avatar_url': 'https://tenant.test/artist-avatar.png',
          'cover_url': 'https://tenant.test/artist-cover.png',
          'taxonomy_terms': [
            {
              'type': 'genre',
              'value': 'samba',
              'name': 'Samba',
              'taxonomy_name': 'Genero musical',
              'label': 'Legacy Samba',
            },
          ],
        },
      ],
    });

    final domain = dto.toDomain();

    expect(domain.linkedAccountProfiles, hasLength(1));
    expect(domain.linkedAccountProfiles.first.profileType, 'artist');
    expect(domain.linkedAccountProfiles.first.slug, 'ananda-torres');
    final term = domain.linkedAccountProfiles.first.taxonomyTerms.first;
    expect(term.valueValue.value, 'samba');
    expect(term.taxonomyNameValue.value, 'Genero musical');
    expect(term.compatibilityLabelValue.value, 'Legacy Samba');
    expect(term.labelValue.value, 'Samba');
  });

  test('falls back linked account profile taxonomy labels to value', () {
    final dto = EventDTO.fromJson({
      'event_id': '69a77aa3680219d56909080f',
      'slug': 'evt-linked-legacy-taxonomy',
      'type': {
        'id': '69a77aa3680219d569090810',
        'name': 'Show',
        'slug': 'show',
        'description': '',
      },
      'title': 'Evento com perfis',
      'content': 'Descricao',
      'location': 'Carvoeiro',
      'date_time_start': '2026-03-03T10:00:00+00:00',
      'linked_account_profiles': [
        {
          'id': 'artist-1',
          'display_name': 'Ananda Torres',
          'slug': 'ananda-torres',
          'profile_type': 'artist',
          'taxonomy_terms': [
            {'type': 'genre', 'value': 'samba'},
          ],
        },
      ],
    });

    final domain = dto.toDomain();
    final term = domain.linkedAccountProfiles.first.taxonomyTerms.first;

    expect(term.taxonomyNameValue.value, isEmpty);
    expect(term.compatibilityLabelValue.value, isEmpty);
    expect(term.labelValue.value, 'samba');
  });

  test('does not synthesize linked account profiles from artists or venue', () {
    final dto = EventDTO.fromJson({
      'event_id': '69a77aa3680219d56909080f',
      'slug': 'evt-linked-cutover',
      'type': {
        'id': '69a77aa3680219d569090810',
        'name': 'Show',
        'slug': 'show',
        'description': '',
      },
      'title': 'Evento canônico',
      'content': 'Descricao',
      'location': 'Carvoeiro',
      'date_time_start': '2026-03-03T10:00:00+00:00',
      'venue': {
        'id': '69c558629b497835b900ac86',
        'display_name': 'Carvoeiro',
        'slug': 'carvoeiro',
      },
      'linked_account_profiles': const [],
    });

    final domain = dto.toDomain();

    expect(domain.linkedAccountProfiles, isEmpty);
  });

  test('accepts account-profile slug aliases in linked account profiles', () {
    final dto = EventDTO.fromJson({
      'event_id': '69a77aa3680219d56909081a',
      'slug': 'evt-aliased-slug',
      'type': {
        'id': 'show',
        'name': 'Show',
        'slug': 'show',
        'description': '',
      },
      'title': 'Evento com alias',
      'content': 'Descricao',
      'location': 'Carvoeiro',
      'date_time_start': '2026-03-03T10:00:00+00:00',
      'linked_account_profiles': [
        {
          'id': 'artist-1',
          'display_name': 'Ananda Torres',
          'profile_type': 'artist',
          'account_profile_slug': 'ananda-torres',
        },
      ],
    });

    final domain = dto.toDomain();

    expect(domain.linkedAccountProfiles, hasLength(1));
    expect(domain.linkedAccountProfiles.first.slug, 'ananda-torres');
  });

  test('keeps linked account profile readable when public detail is disabled',
      () {
    final dto = EventDTO.fromJson({
      'event_id': '69a77aa3680219d56909081b',
      'slug': 'evt-missing-linked-slug',
      'type': {
        'id': 'show',
        'name': 'Show',
        'slug': 'show',
        'description': '',
      },
      'title': 'Evento inconsistente',
      'content': 'Descricao',
      'location': 'Carvoeiro',
      'date_time_start': '2026-03-03T10:00:00+00:00',
      'linked_account_profiles': [
        {
          'id': 'artist-1',
          'display_name': 'Ananda Torres',
          'profile_type': 'artist',
          'can_open_public_detail': false,
        },
      ],
    });

    expect(dto.linkedAccountProfiles, hasLength(1));
    expect(dto.linkedAccountProfiles.first.slug, isEmpty);
    expect(dto.linkedAccountProfiles.first.canOpenPublicDetail, isFalse);
  });

  test('parses event detail occurrences and selected programming items', () {
    final dto = EventDTO.fromJson({
      'event_id': '507f1f77bcf86cd799439081',
      'occurrence_id': '507f1f77bcf86cd799439083',
      'slug': 'festival-de-verao',
      'type': {
        'id': 'show',
        'name': 'Show',
        'slug': 'show',
        'description': '',
      },
      'title': 'Festival de Verao',
      'content': 'Descricao',
      'location': 'Praca Central',
      'date_time_start': '2026-03-04T17:00:00+00:00',
      'linked_account_profiles': const [],
      'occurrences': [
        {
          'occurrence_id': '507f1f77bcf86cd799439082',
          'occurrence_slug': 'festival-de-verao-1',
          'date_time_start': '2026-03-03T17:00:00+00:00',
          'date_time_end': '2026-03-03T21:00:00+00:00',
          'is_selected': false,
          'has_location_override': false,
          'programming_count': 0,
        },
        {
          'occurrence_id': '507f1f77bcf86cd799439083',
          'occurrence_slug': 'festival-de-verao-2',
          'date_time_start': '2026-03-04T17:00:00+00:00',
          'date_time_end': '2026-03-04T21:00:00+00:00',
          'is_selected': true,
          'has_location_override': true,
          'programming_count': 1,
        },
      ],
      'programming_items': [
        {
          'time': '17:00',
          'end_time': '18:30',
          'title': null,
          'linked_account_profiles': [
            {
              'id': 'artist-1',
              'display_name': 'Coral XYZ',
              'slug': 'coral-xyz',
              'profile_type': 'artist',
            },
          ],
          'location_profile': {
            'id': 'venue-1',
            'display_name': 'Palco Central',
            'slug': 'palco-central',
            'profile_type': 'venue',
            'location': {
              'type': 'Point',
              'coordinates': [-40.495395, -20.671339],
            },
          },
        },
      ],
    });

    final domain = dto.toDomain();

    expect(domain.occurrences, hasLength(2));
    expect(domain.hasMultipleOccurrences, isTrue);
    expect(domain.selectedOccurrenceId, '507f1f77bcf86cd799439083');
    expect(domain.selectedOccurrence!.hasLocationOverride, isTrue);
    expect(domain.selectedOccurrence!.programmingCount, 1);
    expect(domain.programmingItems, hasLength(1));
    expect(domain.programmingItems.first.time, '17:00');
    expect(domain.programmingItems.first.endTime, '18:30');
    expect(domain.programmingItems.first.displayTitle, isEmpty);
    expect(domain.programmingItems.first.linkedAccountProfiles, hasLength(1));
    expect(domain.programmingItems.first.locationProfile?.displayName,
        'Palco Central');
    expect(domain.programmingItems.first.locationProfile?.locationLat,
        closeTo(-20.671339, 0.000001));
    expect(domain.programmingItems.first.locationProfile?.locationLng,
        closeTo(-40.495395, 0.000001));
  });

  test('maps online occurrence location label into non-empty domain location',
      () {
    final dto = EventDTO.fromJson({
      'event_id': '507f1f77bcf86cd799439081',
      'occurrence_id': '507f1f77bcf86cd799439084',
      'slug': 'festival-online',
      'type': {
        'id': 'show',
        'name': 'Show',
        'slug': 'show',
        'description': '',
      },
      'title': 'Festival Online',
      'content': 'Descricao',
      'location': {
        'mode': 'online',
        'online': {
          'url': 'https://example.org/live',
          'label': 'Transmissao ao vivo',
        },
      },
      'place_ref': null,
      'venue': null,
      'date_time_start': '2026-03-04T17:00:00+00:00',
      'linked_account_profiles': const [],
      'occurrences': [
        {
          'occurrence_id': '507f1f77bcf86cd799439084',
          'date_time_start': '2026-03-04T17:00:00+00:00',
          'is_selected': true,
          'has_location_override': true,
          'programming_count': 1,
        },
      ],
      'programming_items': [
        {
          'time': '17:00',
          'title': 'Show com a banda',
          'linked_account_profiles': [
            {
              'id': 'artist-1',
              'display_name': 'Coral XYZ',
              'slug': 'coral-xyz',
              'profile_type': 'artist',
            },
          ],
        },
      ],
    });

    final domain = dto.toDomain();

    expect(dto.location, 'Transmissao ao vivo');
    expect(domain.location.value, 'Transmissao ao vivo');
    expect(domain.hasProgrammingItems, isTrue);
  });

  test('parses effective occurrence taxonomy labels for selected occurrence',
      () {
    final dto = EventDTO.fromJson({
      'event_id': '507f1f77bcf86cd799439085',
      'occurrence_id': '507f1f77bcf86cd799439086',
      'slug': 'festival-taxonomia-por-ocorrencia',
      'type': {
        'id': 'show',
        'name': 'Show',
        'slug': 'show',
        'description': '',
      },
      'title': 'Festival taxonomia por ocorrencia',
      'content': 'Descricao',
      'location': 'Praca Central',
      'date_time_start': '2026-03-04T17:00:00+00:00',
      'taxonomy_terms': [
        {
          'type': 'event_style',
          'value': 'showcase',
          'label': 'Showcase',
        },
      ],
      'occurrences': [
        {
          'occurrence_id': '507f1f77bcf86cd799439086',
          'date_time_start': '2026-03-04T17:00:00+00:00',
          'is_selected': true,
          'taxonomy_terms': [
            {
              'type': 'event_style',
              'value': 'instrumental',
              'label': 'Instrumental',
            },
          ],
        },
      ],
    });

    final occurrence = dto.toDomain().occurrences.single;

    expect(occurrence.tags.map((tag) => tag.value), ['Instrumental']);
  });
}

AppData _buildAppData() {
  return buildAppDataFromInitialization(
    remoteData: {
      'name': 'Tenant Test',
      'type': 'tenant',
      'main_domain': 'https://tenant.test',
      'profile_types': const [
        {
          'type': 'artist',
          'label': 'Artist',
          'labels': {'singular': 'Artist', 'plural': 'Artists'},
          'capabilities': {'has_events': true, 'is_favoritable': true},
        },
      ],
      'theme_data_settings': const {
        'primary_seed_color': '#FFFFFF',
        'secondary_seed_color': '#3355FF',
      },
    },
    localInfo: {
      'platformType': 'mobile',
      'hostname': 'tenant.test',
      'href': 'https://tenant.test',
      'device': 'test-device',
    },
  );
}

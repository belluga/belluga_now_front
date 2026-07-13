import 'package:belluga_contact_channels/belluga_contact_channels.dart';
import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';
import 'package:belluga_now/domain/map/value_objects/distance_in_meters_value.dart';
import 'package:belluga_now/domain/map/value_objects/latitude_value.dart';
import 'package:belluga_now/domain/map/value_objects/longitude_value.dart';
import 'package:belluga_now/domain/partners/account_profile_gallery_group.dart';
import 'package:belluga_now/domain/partners/account_profile_model.dart';
import 'package:belluga_now/domain/partners/projections/partner_profile_config.dart';
import 'package:belluga_now/domain/partners/projections/partner_profile_module_data.dart';
import 'package:belluga_now/domain/partners/paged_account_profiles_result.dart';
import 'package:belluga_now/domain/proximity_preferences/proximity_preference.dart';
import 'package:belluga_now/domain/repositories/account_profiles_repository_contract.dart';
import 'package:belluga_now/domain/repositories/auth_repository_contract.dart';
import 'package:belluga_now/domain/repositories/invites_repository_contract.dart';
import 'package:belluga_now/domain/repositories/proximity_preferences_repository_contract.dart';
import 'package:belluga_now/domain/repositories/telemetry_repository_contract.dart';
import 'package:belluga_now/domain/repositories/user_events_repository_contract.dart';
import 'package:belluga_now/domain/repositories/value_objects/telemetry_repository_contract_values.dart';
import 'package:belluga_now/domain/repositories/value_objects/user_events_repository_contract_values.dart';
import 'package:belluga_now/domain/schedule/sent_invite_status.dart';
import 'package:belluga_now/domain/shared/account_profile_contact_source_summary.dart';
import 'package:belluga_now/domain/invites/invite_accept_result.dart';
import 'package:belluga_now/domain/invites/invite_decline_result.dart';
import 'package:belluga_now/domain/invites/invite_materialize_result.dart';
import 'package:belluga_now/domain/invites/invite_model.dart';
import 'package:belluga_now/domain/invites/invite_runtime_settings.dart';
import 'package:belluga_now/domain/invites/invite_share_code_result.dart';
import 'package:belluga_now/domain/invites/invite_contact_match.dart';
import 'package:belluga_now/domain/user/user_contract.dart';
import 'package:belluga_now/presentation/tenant_public/partners/controllers/account_profile_detail_controller.dart';
import 'package:belluga_now/infrastructure/services/telemetry/telemetry_properties_codec.dart';
import 'package:belluga_now/testing/account_profile_model_factory.dart';
import 'package:belluga_now/testing/app_data_test_factory.dart';
import 'package:belluga_now/testing/domain_factories.dart';
import 'package:belluga_now/testing/invite_model_factory.dart';
import 'package:belluga_now/domain/venue_event/projections/venue_event_resume.dart';
import 'package:event_tracker_handler/event_tracker_handler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value.dart';

void main() {
  test(
    'loadResolvedAccountProfile exposes occurrence-first agenda module directly from profile payload',
    () async {
      final accountProfileRepository = _FakeAccountProfilesRepository();
      final controller = AccountProfileDetailController(
        accountProfilesRepository: accountProfileRepository,
      );
      final profile = buildAccountProfileModelFromPrimitives(
        id: '507f1f77bcf86cd799439011',
        name: 'Cafe de la Musique',
        slug: 'cafe-de-la-musique',
        type: 'venue',
        agendaEvents: [
          buildPartnerEventView(
            eventId: '507f1f77bcf86cd799439021',
            occurrenceId: '507f1f77bcf86cd799439121',
            slug: 'jazz-na-orla',
            title: 'Jazz na Orla',
            location: 'Deck Principal',
            startDateTime: DateTime.now().toUtc().subtract(
              const Duration(minutes: 45),
            ),
            endDateTime: DateTime.now().toUtc().add(const Duration(hours: 1)),
            artistNames: const ['Marco Aurélio'],
          ),
          buildPartnerEventView(
            eventId: '507f1f77bcf86cd799439021',
            occurrenceId: '507f1f77bcf86cd799439122',
            slug: 'jazz-na-orla',
            title: 'Jazz na Orla',
            location: 'Deck Principal',
            startDateTime: DateTime.now().toUtc().add(const Duration(days: 1)),
            artistNames: const ['Marco Aurélio'],
          ),
        ],
      );

      await controller.loadResolvedAccountProfile(profile);

      final config = controller.profileConfigStreamValue.value;
      final agendaData =
          controller.moduleDataStreamValue.value[ProfileModuleId.agendaList];

      expect(config?.tabs.any((tab) => tab.title.contains('Agenda')), isTrue);
      expect(agendaData, isA<List<PartnerEventView>>());
      final events = agendaData! as List<PartnerEventView>;
      expect(events, hasLength(2));
      expect(events.first.slug, 'jazz-na-orla');
      expect(events.first.primaryCounterpart?.title, 'Marco Aurélio');
      expect(events.first.uniqueId, isNot(equals(events.last.uniqueId)));
    },
  );

  test(
    'loadResolvedAccountProfile exposes location module when profile has coordinates',
    () async {
      final accountProfileRepository = _FakeAccountProfilesRepository();
      final controller = AccountProfileDetailController(
        accountProfilesRepository: accountProfileRepository,
      );
      final profile = buildAccountProfileModelFromPrimitives(
        id: '507f1f77bcf86cd799439011',
        name: 'Casa Marracini',
        slug: 'casa-marracini',
        type: 'restaurant',
        locationLat: -20.7389,
        locationLng: -40.8212,
      );

      await controller.loadResolvedAccountProfile(profile);

      final locationData =
          controller.moduleDataStreamValue.value[ProfileModuleId.locationInfo];

      expect(locationData, isA<PartnerLocationView>());
      final location = locationData! as PartnerLocationView;
      expect(location.lat, '-20.7389');
      expect(location.lng, '-40.8212');
      expect(location.address, isEmpty);
    },
  );

  test(
    'loadResolvedAccountProfile exposes grouped gallery module when gallery exists',
    () async {
      await _registerGalleryAppData(galleryEnabled: true);
      final accountProfileRepository = _FakeAccountProfilesRepository();
      final controller = AccountProfileDetailController(
        accountProfilesRepository: accountProfileRepository,
      );
      final profile = buildAccountProfileModelFromPrimitives(
        id: '507f1f77bcf86cd799439011',
        name: 'Cafe de la Musique',
        slug: 'cafe-de-la-musique',
        type: 'artist',
        galleryGroups: [
          buildAccountProfileGalleryGroupFromPrimitives(
            groupId: 'group-1',
            subtitle: 'Ambiente',
            items: [
              buildAccountProfileGalleryItemFromPrimitives(
                itemId: 'gallery-item-1',
                description: 'Vista para o palco',
                imageUrl: 'https://tenant.test/gallery/image.jpg',
                thumbUrl: 'https://tenant.test/gallery/thumb.jpg',
                cardUrl: 'https://tenant.test/gallery/card.jpg',
                modalUrl: 'https://tenant.test/gallery/modal.jpg',
              ),
            ],
          ),
        ],
      );

      await controller.loadResolvedAccountProfile(profile);

      final config = controller.profileConfigStreamValue.value;
      final galleryData =
          controller.moduleDataStreamValue.value[ProfileModuleId.photoGallery];

      expect(config?.tabs.any((tab) => tab.title.contains('Sobre')), isTrue);
      expect(galleryData, isA<List<AccountProfileGalleryGroup>>());
      final groups = galleryData! as List<AccountProfileGalleryGroup>;
      expect(groups, hasLength(1));
      expect(groups.first.subtitle, 'Ambiente');
      expect(groups.first.items.first.description, 'Vista para o palco');
    },
  );

  test(
    'loadResolvedAccountProfile suppresses gallery module when gallery capability is disabled',
    () async {
      await _registerGalleryAppData(galleryEnabled: false);
      final controller = AccountProfileDetailController(
        accountProfilesRepository: _FakeAccountProfilesRepository(),
      );
      final profile = buildAccountProfileModelFromPrimitives(
        id: '507f1f77bcf86cd799439011',
        name: 'Cafe de la Musique',
        slug: 'cafe-de-la-musique',
        type: 'artist',
        galleryGroups: [
          buildAccountProfileGalleryGroupFromPrimitives(
            groupId: 'group-1',
            subtitle: 'Ambiente',
            items: [
              buildAccountProfileGalleryItemFromPrimitives(
                itemId: 'gallery-item-1',
                imageUrl: 'https://tenant.test/gallery/image.jpg',
                thumbUrl: 'https://tenant.test/gallery/thumb.jpg',
                cardUrl: 'https://tenant.test/gallery/card.jpg',
                modalUrl: 'https://tenant.test/gallery/modal.jpg',
              ),
            ],
          ),
        ],
      );

      await controller.loadResolvedAccountProfile(profile);

      expect(
        controller.moduleDataStreamValue.value[ProfileModuleId.photoGallery],
        isNull,
      );
    },
  );

  test(
    'loadResolvedAccountProfile omits the gallery module when capability data has no gallery groups',
    () async {
      await _registerGalleryAppData(galleryEnabled: true, hasBio: true);
      final controller = AccountProfileDetailController(
        accountProfilesRepository: _FakeAccountProfilesRepository(),
      );
      final profile = buildAccountProfileModelFromPrimitives(
        id: '507f1f77bcf86cd799439011',
        name: 'Cafe de la Musique',
        slug: 'cafe-de-la-musique',
        type: 'artist',
        bio: '<p>Bio sem galeria</p>',
        galleryGroups: const [],
      );

      await controller.loadResolvedAccountProfile(profile);

      final aboutTab = controller.profileConfigStreamValue.value?.tabs
          .firstWhere((tab) => tab.title.contains('Sobre'));

      expect(aboutTab, isNotNull);
      expect(
        aboutTab?.modules.map((module) => module.id),
        isNot(contains(ProfileModuleId.photoGallery)),
      );
      expect(
        controller.moduleDataStreamValue.value[ProfileModuleId.photoGallery],
        isNull,
      );
    },
  );

  test(
    'contact helpers expose only resolvable effective channels and bubble selections when capability is enabled',
    () async {
      await _registerContactAppData(contactEnabled: true);
      final controller = AccountProfileDetailController(
        accountProfilesRepository: _FakeAccountProfilesRepository(),
      );
      final whatsappChannel = BellugaContactChannel(
        id: 'whatsapp-primary',
        type: BellugaContactChannelType.whatsapp,
        value: '+55 (27) 99999-9999',
        title: 'Atendimento',
      );
      final invalidEmail = BellugaContactChannel(
        id: 'email-primary',
        type: BellugaContactChannelType.email,
        value: 'email-invalido',
      );
      final profile = buildAccountProfileModelFromPrimitives(
        id: '507f1f77bcf86cd799439011',
        name: 'Cafe de la Musique',
        slug: 'cafe-de-la-musique',
        type: 'artist',
        contactChannels: [invalidEmail, whatsappChannel],
        effectiveContactChannels: [invalidEmail, whatsappChannel],
        contactBubbleChannelId: whatsappChannel.id,
      );

      expect(controller.hasContactChannels(profile), isTrue);
      expect(controller.availableContactChannelsFor(profile), [
        whatsappChannel,
      ]);
      expect(controller.shouldRenderContactTab(profile), isTrue);
      expect(
        controller.resolvedBubbleChannelFor(profile)?.id,
        whatsappChannel.id,
      );
    },
  );

  test(
    'contact bubble fails closed for a resolvable non-bubble channel',
    () async {
      await _registerContactAppData(contactEnabled: true);
      final controller = AccountProfileDetailController(
        accountProfilesRepository: _FakeAccountProfilesRepository(),
      );
      final emailChannel = BellugaContactChannel(
        id: 'email-primary',
        type: BellugaContactChannelType.email,
        value: 'contato@example.test',
      );
      final profile = buildAccountProfileModelFromPrimitives(
        id: '507f1f77bcf86cd799439015',
        name: 'Perfil com ponteiro inválido',
        slug: 'perfil-com-ponteiro-invalido',
        type: 'artist',
        contactChannels: [emailChannel],
        effectiveContactChannels: [emailChannel],
        contactBubbleChannelId: emailChannel.id,
      );

      expect(controller.shouldRenderContactTab(profile), isTrue);
      expect(controller.resolvedBubbleChannelFor(profile), isNull);
    },
  );

  test(
    'contact bubble impression telemetry is emitted only once per channel',
    () async {
      await _registerContactAppData(contactEnabled: true);
      final telemetry = _RecordingTelemetryRepository();
      final controller = AccountProfileDetailController(
        accountProfilesRepository: _FakeAccountProfilesRepository(),
        telemetryRepository: telemetry,
      );
      final whatsappChannel = BellugaContactChannel(
        id: 'whatsapp-primary',
        type: BellugaContactChannelType.whatsapp,
        value: '+55 (27) 99999-9999',
      );
      final profile = buildAccountProfileModelFromPrimitives(
        id: '507f1f77bcf86cd799439012',
        name: 'Casa do Som',
        slug: 'casa-do-som',
        type: 'artist',
        contactChannels: [whatsappChannel],
        effectiveContactChannels: [whatsappChannel],
        contactBubbleChannelId: whatsappChannel.id,
      );

      controller.trackContactBubbleImpression(profile);
      controller.trackContactBubbleImpression(profile);
      await Future<void>.delayed(Duration.zero);

      expect(telemetry.loggedEvents, hasLength(1));
      expect(
        telemetry.loggedEvents.single.eventName,
        'account_profile_contact_bubble_impression',
      );
      expect(
        telemetry.loggedEvents.single.event,
        EventTrackerEvents.viewContent,
      );
      expect(
        telemetry.loggedEvents.single.properties?['channel_id'],
        whatsappChannel.id,
      );
    },
  );

  test(
    'contact CTA telemetry carries mirrored-source attribution and CTA metadata',
    () async {
      await _registerContactAppData(contactEnabled: true);
      final telemetry = _RecordingTelemetryRepository();
      final controller = AccountProfileDetailController(
        accountProfilesRepository: _FakeAccountProfilesRepository(),
        telemetryRepository: telemetry,
      );
      final initialMessage = BellugaContactInitialMessage(
        id: 'wa-cta-1',
        cta: 'Quero falar',
        message: 'Quero falar sobre o perfil.',
      );
      final whatsappChannel = BellugaContactChannel(
        id: 'whatsapp-primary',
        type: BellugaContactChannelType.whatsapp,
        value: '+55 (27) 99999-9999',
        initialMessages: [initialMessage],
      );
      final profile = buildAccountProfileModelFromPrimitives(
        id: '507f1f77bcf86cd799439013',
        name: 'Cafe de la Musique',
        slug: 'cafe-de-la-musique',
        type: 'artist',
        contactMode: BellugaContactSourceMode.mirroredAccountProfile,
        contactSourceAccountProfileId: '507f1f77bcf86cd799439099',
        effectiveContactChannels: [whatsappChannel],
        contactBubbleChannelId: whatsappChannel.id,
        effectiveContactSourceProfile: const AccountProfileContactSourceSummary(
          id: '507f1f77bcf86cd799439099',
          displayName: 'Perfil Origem',
          profileType: 'artist',
        ),
      );

      controller.trackContactCtaTap(
        profile,
        channel: whatsappChannel,
        initialMessage: initialMessage,
        origin: 'bubble',
      );
      await Future<void>.delayed(Duration.zero);

      expect(telemetry.loggedEvents, hasLength(1));
      final logged = telemetry.loggedEvents.single;
      expect(logged.eventName, 'account_profile_contact_cta_tap');
      expect(logged.event, EventTrackerEvents.buttonClick);
      expect(
        logged.properties?['contact_source_mode'],
        'mirrored_account_profile',
      );
      expect(
        logged.properties?['contact_source_profile_id'],
        '507f1f77bcf86cd799439099',
      );
      expect(logged.properties?['cta_id'], 'wa-cta-1');
      expect(logged.properties?['cta_label'], 'Quero falar');
      expect(logged.properties?['surface_origin'], 'bubble');
    },
  );

  test('contact telemetry emits the canonical five-event matrix', () async {
    await _registerContactAppData(contactEnabled: true);
    final telemetry = _RecordingTelemetryRepository();
    final controller = AccountProfileDetailController(
      accountProfilesRepository: _FakeAccountProfilesRepository(),
      telemetryRepository: telemetry,
    );
    final initialMessage = BellugaContactInitialMessage(
      id: 'cta-canonical',
      cta: 'Quero falar',
      message: 'Quero falar sobre este perfil.',
    );
    final channel = BellugaContactChannel(
      id: 'whatsapp-primary',
      type: BellugaContactChannelType.whatsapp,
      value: '+55 (27) 99999-9999',
      initialMessages: [initialMessage],
    );
    final profile = buildAccountProfileModelFromPrimitives(
      id: '507f1f77bcf86cd799439017',
      name: 'Perfil de contato',
      slug: 'perfil-de-contato',
      type: 'artist',
      effectiveContactChannels: [channel],
      contactBubbleChannelId: channel.id,
    );

    controller.trackContactBubbleImpression(profile);
    controller.trackContactBubbleTap(profile);
    controller.trackContactChooserOpen(
      profile,
      channel: channel,
      origin: 'bubble',
    );
    controller.trackContactCtaTap(
      profile,
      channel: channel,
      initialMessage: initialMessage,
      origin: 'bubble',
    );
    controller.trackContactDirectClick(
      profile,
      channel: channel,
      origin: 'contact_tab',
    );
    await Future<void>.delayed(Duration.zero);

    expect(telemetry.loggedEvents.map((event) => event.eventName), [
      'account_profile_contact_bubble_impression',
      'account_profile_contact_bubble_tap',
      'account_profile_contact_chooser_open',
      'account_profile_contact_cta_tap',
      'account_profile_contact_direct_click',
    ]);
    for (final event in telemetry.loggedEvents) {
      expect(event.properties?['account_profile_id'], profile.id);
      expect(event.properties?['channel_id'], channel.id);
      expect(event.properties?['channel_type'], 'whatsapp');
      expect(event.properties?['contact_source_mode'], 'own');
    }
    expect(telemetry.loggedEvents[3].properties?['cta_id'], initialMessage.id);
    expect(
      telemetry.loggedEvents[3].properties?['cta_label'],
      initialMessage.cta,
    );
  });

  test(
    'controller resolves invite status and distance for agenda cards',
    () async {
      final accountProfileRepository = _FakeAccountProfilesRepository();
      final userEventsRepository = _FakeUserEventsRepository(
        confirmedIds: const {'507f1f77bcf86cd799439131'},
      );
      final invitesRepository = _FakeInvitesRepository(
        invites: [
          buildInviteModelFromPrimitives(
            id: 'invite-1',
            eventId: '507f1f77bcf86cd799439031',
            eventName: 'Chef Table Experience',
            eventDateTime: DateTime.now().toUtc(),
            eventImageUrl: 'https://example.com/chef-table.jpg',
            location: 'Casa Marracini',
            hostName: 'Casa Marracini',
            message: 'Convite pendente',
            occurrenceId: '507f1f77bcf86cd799439131',
            tags: const [],
            inviterName: 'Tester',
          ),
        ],
      );
      final controller = AccountProfileDetailController(
        accountProfilesRepository: accountProfileRepository,
        userEventsRepository: userEventsRepository,
        invitesRepository: invitesRepository,
      );
      final profile = buildAccountProfileModelFromPrimitives(
        id: '507f1f77bcf86cd799439015',
        name: 'Casa Marracini',
        slug: 'casa-marracini',
        type: 'restaurant',
        distanceMeters: 752,
      );
      final event = buildPartnerEventView(
        eventId: '507f1f77bcf86cd799439031',
        occurrenceId: '507f1f77bcf86cd799439131',
        slug: 'chef-table',
        title: 'Chef Table Experience',
        location: 'Salão Principal',
        venueId: '507f1f77bcf86cd799439015',
        venueTitle: 'Casa Marracini',
      );

      expect(controller.isOccurrenceConfirmed(event.occurrenceId), isTrue);
      expect(controller.pendingInviteCount(event.occurrenceId), 1);
      expect(controller.distanceLabelFor(profile, event), '752 m');
    },
  );

  test('toggleFavorite requires authentication for anonymous users', () {
    final accountProfileRepository = _FakeAccountProfilesRepository();
    final controller = AccountProfileDetailController(
      accountProfilesRepository: accountProfileRepository,
      authRepository: _FakeAuthRepository(authorized: false),
    );

    final result = controller.toggleFavorite('507f1f77bcf86cd799439011');

    expect(result, AccountProfileFavoriteToggleOutcome.requiresAuthentication);
    expect(accountProfileRepository.toggleFavoriteCalls, isEmpty);
  });

  test(
    'setAsReferencePoint persists account profile provenance and coordinate snapshot',
    () async {
      await _registerReferenceAppData(referenceLocationEnabled: true);
      final proximityRepository = _FakeProximityPreferencesRepository();
      final controller = AccountProfileDetailController(
        accountProfilesRepository: _FakeAccountProfilesRepository(),
        proximityPreferencesRepository: proximityRepository,
      );
      final profile = _buildReferenceProfile();

      final saved = await controller.setAsReferencePoint(profile);

      expect(saved, isTrue);
      final fixedReference = proximityRepository.lastFixedReference;
      expect(fixedReference, isNotNull);
      expect(
        fixedReference!.sourceKind,
        FixedLocationReferenceSourceKind.entityReference,
      );
      expect(fixedReference.label, 'Casa Marracini');
      expect(fixedReference.entityNamespace, 'account_profile');
      expect(fixedReference.entityType, 'restaurant');
      expect(fixedReference.entityId, '507f1f77bcf86cd799439012');
      expect(fixedReference.entitySlug, 'casa-marracini');
      expect(fixedReference.coordinate.latitude, closeTo(-20.7389, 0.000001));
      expect(fixedReference.coordinate.longitude, closeTo(-40.8212, 0.000001));
    },
  );

  test(
    'reference point eligibility requires capability and coordinates',
    () async {
      await _registerReferenceAppData(referenceLocationEnabled: true);
      final controller = AccountProfileDetailController(
        accountProfilesRepository: _FakeAccountProfilesRepository(),
        proximityPreferencesRepository: _FakeProximityPreferencesRepository(),
      );

      expect(
        controller.canUseAsReferencePoint(_buildReferenceProfile()),
        isTrue,
      );
      expect(
        controller.canUseAsReferencePoint(
          _buildReferenceProfile(locationLat: null, locationLng: null),
        ),
        isFalse,
      );

      await _registerReferenceAppData(referenceLocationEnabled: false);
      expect(
        controller.canUseAsReferencePoint(_buildReferenceProfile()),
        isFalse,
      );
    },
  );

  test(
    'isCurrentReferencePoint matches active account profile provenance',
    () async {
      await _registerReferenceAppData(referenceLocationEnabled: true);
      final profile = _buildReferenceProfile();
      final proximityRepository = _FakeProximityPreferencesRepository(
        fixedReference: _fixedReferenceFor(profile),
      );
      final controller = AccountProfileDetailController(
        accountProfilesRepository: _FakeAccountProfilesRepository(),
        proximityPreferencesRepository: proximityRepository,
      );

      expect(controller.isCurrentReferencePoint(profile), isTrue);
      expect(
        controller.isCurrentReferencePoint(
          _buildReferenceProfile(
            id: '507f1f77bcf86cd799439099',
            slug: 'outra-casa',
          ),
        ),
        isFalse,
      );
    },
  );
}

Future<void> _registerReferenceAppData({
  required bool referenceLocationEnabled,
}) async {
  await GetIt.I.reset(dispose: false);
  GetIt.I.registerSingleton<AppData>(
    buildAppDataFromInitialization(
      remoteData: {
        'name': 'Tenant Test',
        'type': 'tenant',
        'main_domain': 'https://tenant.test',
        'profile_types': [
          {
            'type': 'restaurant',
            'label': 'Restaurante',
            'allowed_taxonomies': [],
            'capabilities': {
              'is_favoritable': true,
              'is_poi_enabled': true,
              'is_reference_location_enabled': referenceLocationEnabled,
              'has_events': false,
              'has_bio': false,
            },
          },
        ],
        'domains': ['https://tenant.test'],
        'app_domains': const [],
        'theme_data_settings': {
          'brightness_default': 'light',
          'primary_seed_color': '#FFFFFF',
          'secondary_seed_color': '#7E22CE',
        },
        'main_color': '#7E22CE',
        'tenant_id': 'tenant-1',
        'telemetry': const {'trackers': []},
        'telemetry_context': const {'location_freshness_minutes': 5},
        'firebase': null,
        'push': null,
      },
      localInfo: const {
        'platformType': 'mobile',
        'hostname': 'tenant.test',
        'href': 'https://tenant.test',
        'port': null,
        'device': 'test-device',
      },
    ),
  );
}

Future<void> _registerGalleryAppData({
  required bool galleryEnabled,
  bool hasBio = false,
  bool hasContent = false,
}) async {
  await GetIt.I.reset(dispose: false);
  GetIt.I.registerSingleton<AppData>(
    buildAppDataFromInitialization(
      remoteData: {
        'name': 'Tenant Test',
        'type': 'tenant',
        'main_domain': 'https://tenant.test',
        'profile_types': [
          {
            'type': 'artist',
            'label': 'Artista',
            'allowed_taxonomies': [],
            'capabilities': {
              'is_favoritable': true,
              'is_poi_enabled': false,
              'has_events': false,
              'has_bio': hasBio,
              'has_content': hasContent,
              'has_gallery': galleryEnabled,
            },
          },
        ],
        'domains': ['https://tenant.test'],
        'app_domains': const [],
        'theme_data_settings': {
          'brightness_default': 'light',
          'primary_seed_color': '#FFFFFF',
          'secondary_seed_color': '#7E22CE',
        },
        'main_color': '#7E22CE',
        'tenant_id': 'tenant-1',
        'telemetry': const {'trackers': []},
        'telemetry_context': const {'location_freshness_minutes': 5},
        'firebase': null,
        'push': null,
      },
      localInfo: const {
        'platformType': 'mobile',
        'hostname': 'tenant.test',
        'href': 'https://tenant.test',
        'port': null,
        'device': 'test-device',
      },
    ),
  );
}

Future<void> _registerContactAppData({required bool contactEnabled}) async {
  await GetIt.I.reset(dispose: false);
  GetIt.I.registerSingleton<AppData>(
    buildAppDataFromInitialization(
      remoteData: {
        'name': 'Tenant Test',
        'type': 'tenant',
        'main_domain': 'https://tenant.test',
        'profile_types': [
          {
            'type': 'artist',
            'label': 'Artista',
            'allowed_taxonomies': [],
            'capabilities': {
              'is_favoritable': true,
              'is_poi_enabled': false,
              'has_events': false,
              'has_bio': false,
              'has_contact_channels': contactEnabled,
            },
          },
        ],
        'domains': ['https://tenant.test'],
        'app_domains': const [],
        'theme_data_settings': {
          'brightness_default': 'light',
          'primary_seed_color': '#FFFFFF',
          'secondary_seed_color': '#7E22CE',
        },
        'main_color': '#7E22CE',
        'tenant_id': 'tenant-1',
        'telemetry': const {'trackers': []},
        'telemetry_context': const {'location_freshness_minutes': 5},
        'firebase': null,
        'push': null,
      },
      localInfo: const {
        'platformType': 'mobile',
        'hostname': 'tenant.test',
        'href': 'https://tenant.test',
        'port': null,
        'device': 'test-device',
      },
    ),
  );
}

AccountProfileModel _buildReferenceProfile({
  String id = '507f1f77bcf86cd799439012',
  String slug = 'casa-marracini',
  double? locationLat = -20.7389,
  double? locationLng = -40.8212,
}) {
  return buildAccountProfileModelFromPrimitives(
    id: id,
    name: 'Casa Marracini',
    slug: slug,
    type: 'restaurant',
    locationLat: locationLat,
    locationLng: locationLng,
  );
}

FixedLocationReference _fixedReferenceFor(AccountProfileModel profile) {
  return FixedLocationReference(
    sourceKind: FixedLocationReferenceSourceKind.entityReference,
    coordinate: CityCoordinate(
      latitudeValue: LatitudeValue()..parse(profile.locationLat.toString()),
      longitudeValue: LongitudeValue()..parse(profile.locationLng.toString()),
    ),
    labelValue: ProximityPreferenceOptionalTextValue.fromRaw(profile.name),
    entityNamespaceValue: ProximityPreferenceOptionalTextValue.fromRaw(
      'account_profile',
    ),
    entityTypeValue: ProximityPreferenceOptionalTextValue.fromRaw(
      profile.profileType,
    ),
    entityIdValue: ProximityPreferenceOptionalTextValue.fromRaw(profile.id),
    entitySlugValue: ProximityPreferenceOptionalTextValue.fromRaw(profile.slug),
  );
}

class _LoggedEvent {
  const _LoggedEvent({
    required this.event,
    required this.eventName,
    required this.properties,
  });

  final EventTrackerEvents event;
  final String? eventName;
  final Map<String, dynamic>? properties;
}

class _RecordingTelemetryRepository implements TelemetryRepositoryContract {
  final List<_LoggedEvent> loggedEvents = <_LoggedEvent>[];

  @override
  Future<TelemetryRepositoryContractPrimBool> logEvent(
    EventTrackerEvents event, {
    TelemetryRepositoryContractPrimString? eventName,
    TelemetryRepositoryContractPrimMap? properties,
  }) async {
    loggedEvents.add(
      _LoggedEvent(
        event: event,
        eventName: eventName?.value,
        properties: properties == null
            ? null
            : TelemetryPropertiesCodec.toRawMap(properties),
      ),
    );
    return telemetryRepoBool(true);
  }

  @override
  Future<EventTrackerTimedEventHandle?> startTimedEvent(
    EventTrackerEvents event, {
    TelemetryRepositoryContractPrimString? eventName,
    TelemetryRepositoryContractPrimMap? properties,
  }) async => null;

  @override
  Future<TelemetryRepositoryContractPrimBool> finishTimedEvent(
    EventTrackerTimedEventHandle handle,
  ) async => telemetryRepoBool(true);

  @override
  Future<TelemetryRepositoryContractPrimBool> flushTimedEvents() async =>
      telemetryRepoBool(true);

  @override
  void setScreenContext(TelemetryRepositoryContractPrimMap? screenContext) {}

  @override
  EventTrackerLifecycleObserver? buildLifecycleObserver() => null;

  @override
  Future<TelemetryRepositoryContractPrimBool> mergeIdentity({
    required TelemetryRepositoryContractPrimString previousUserId,
  }) async => telemetryRepoBool(true);
}

class _FakeAccountProfilesRepository extends AccountProfilesRepositoryContract {
  _FakeAccountProfilesRepository() {
    favoriteAccountProfileIdsStreamValue.addValue(const {});
  }

  final List<AccountProfileModel> _profiles = <AccountProfileModel>[];
  final List<String> toggleFavoriteCalls = <String>[];

  @override
  Future<void> init() async {}

  @override
  Future<PagedAccountProfilesResult> fetchAccountProfilesPage({
    required AccountProfilesRepositoryContractPrimInt page,
    required AccountProfilesRepositoryContractPrimInt pageSize,
    AccountProfilesRepositoryContractPrimString? query,
    AccountProfilesRepositoryContractPrimString? typeFilter,
    List<AccountProfilesRepositoryContractPrimString>? typeFilters,
    List<dynamic>? taxonomyFilters,
  }) async {
    return pagedAccountProfilesResultFromRaw(
      profiles: _profiles,
      hasMore: false,
    );
  }

  @override
  Future<AccountProfileModel?> getAccountProfileBySlug(
    AccountProfilesRepositoryContractPrimString slug,
  ) async {
    for (final profile in _profiles) {
      if (profile.slug == slug.value) {
        return profile;
      }
    }
    return null;
  }

  @override
  Future<List<AccountProfileModel>> fetchNearbyAccountProfiles({
    AccountProfilesRepositoryContractPrimInt? pageSize,
    List<AccountProfilesRepositoryContractPrimString>? typeFilters,
    List<dynamic>? taxonomyFilters,
  }) async => _profiles;

  @override
  Future<void> toggleFavorite(
    AccountProfilesRepositoryContractPrimString accountProfileId,
  ) async {
    toggleFavoriteCalls.add(accountProfileId.value);
  }

  @override
  AccountProfilesRepositoryContractPrimBool isFavorite(
    AccountProfilesRepositoryContractPrimString accountProfileId,
  ) {
    return AccountProfilesRepositoryContractPrimBool.fromRaw(
      false,
      defaultValue: false,
    );
  }

  @override
  List<AccountProfileModel> getFavoriteAccountProfiles() => const [];
}

class _FakeAuthRepository extends Fake
    implements AuthRepositoryContract<UserContract> {
  _FakeAuthRepository({required this.authorized});

  final bool authorized;

  @override
  bool get isAuthorized => authorized;
}

class _FakeProximityPreferencesRepository
    extends ProximityPreferencesRepositoryContract {
  _FakeProximityPreferencesRepository({
    FixedLocationReference? fixedReference,
  }) {
    if (fixedReference != null) {
      setCurrentPreference(_preferenceWith(fixedReference));
    }
  }

  FixedLocationReference? lastFixedReference;

  @override
  Future<void> setFixedReference({
    required FixedLocationReference fixedReference,
  }) async {
    lastFixedReference = fixedReference;
    setCurrentPreference(_preferenceWith(fixedReference));
  }

  ProximityPreference _preferenceWith(FixedLocationReference fixedReference) {
    return ProximityPreference(
      maxDistanceMetersValue: DistanceInMetersValue.fromRaw(25000),
      locationPreference: ProximityLocationPreference.fixedReference(
        fixedReference: fixedReference,
      ),
    );
  }
}

class _FakeUserEventsRepository implements UserEventsRepositoryContract {
  _FakeUserEventsRepository({Set<String> confirmedIds = const {}})
    : _confirmedIds = Set<String>.from(confirmedIds) {
    confirmedOccurrenceIdsStream.addValue(
      _confirmedIds
          .map(
            (value) =>
                userEventsRepoString(value, defaultValue: '', isRequired: true),
          )
          .toSet(),
    );
  }

  final Set<String> _confirmedIds;

  @override
  final confirmedOccurrenceIdsStream =
      StreamValue<Set<UserEventsRepositoryContractPrimString>>(
        defaultValue: const <UserEventsRepositoryContractPrimString>{},
      );

  @override
  Future<void> confirmEventAttendance(
    UserEventsRepositoryContractPrimString eventId, {
    required UserEventsRepositoryContractPrimString occurrenceId,
  }) async {}

  @override
  Future<List<VenueEventResume>> fetchFeaturedEvents() async => const [];

  @override
  Future<List<VenueEventResume>> fetchMyEvents() async => const [];

  @override
  UserEventsRepositoryContractPrimBool isOccurrenceConfirmed(
    UserEventsRepositoryContractPrimString eventId,
  ) => userEventsRepoBool(
    _confirmedIds.contains(eventId.value),
    defaultValue: false,
    isRequired: true,
  );

  @override
  Future<void> refreshConfirmedOccurrenceIds() async {}

  @override
  Future<void> unconfirmEventAttendance(
    UserEventsRepositoryContractPrimString eventId, {
    required UserEventsRepositoryContractPrimString occurrenceId,
  }) async {}
}

class _FakeInvitesRepository extends InvitesRepositoryContract {
  _FakeInvitesRepository({List<InviteModel> invites = const []}) {
    pendingInvitesStreamValue.addValue(List<InviteModel>.from(invites));
  }

  @override
  Future<InviteAcceptResult> acceptInvite(
    InvitesRepositoryContractPrimString inviteId,
  ) async => throw UnimplementedError();

  @override
  Future<InviteAcceptResult> acceptInviteByCode(
    InvitesRepositoryContractPrimString code,
  ) async => throw UnimplementedError();

  @override
  Future<InviteShareCodeResult> createShareCode({
    required InvitesRepositoryContractPrimString eventId,
    InvitesRepositoryContractPrimString? occurrenceId,
    InvitesRepositoryContractPrimString? accountProfileId,
  }) async => throw UnimplementedError();

  @override
  Future<InviteDeclineResult> declineInvite(
    InvitesRepositoryContractPrimString inviteId,
  ) async => throw UnimplementedError();

  @override
  Future<List<InviteModel>> fetchInvites({
    InvitesRepositoryContractPrimInt? page,
    InvitesRepositoryContractPrimInt? pageSize,
  }) async => pendingInvitesStreamValue.value;

  @override
  Future<InviteRuntimeSettings> fetchSettings() async =>
      buildInviteRuntimeSettings(
        tenantId: null,
        limits: const {},
        cooldowns: const {},
        overQuotaMessage: null,
      );

  @override
  Future<List<SentInviteStatus>> getSentInvitesForOccurrence(
    InvitesRepositoryContractPrimString eventId,
  ) async => const <SentInviteStatus>[];

  @override
  Future<List<InviteContactMatch>> importContacts(
    InviteContacts contacts,
  ) async => const <InviteContactMatch>[];

  @override
  Future<InviteMaterializeResult> materializeShareCode(
    InvitesRepositoryContractPrimString code,
  ) async => throw UnimplementedError();

  @override
  Future<InviteModel?> previewShareCode(
    InvitesRepositoryContractPrimString code,
  ) async => null;

  @override
  Future<void> sendInvites(
    InvitesRepositoryContractPrimString eventId,
    InviteRecipients recipients, {
    InvitesRepositoryContractPrimString? occurrenceId,
    InvitesRepositoryContractPrimString? message,
  }) async {}
}

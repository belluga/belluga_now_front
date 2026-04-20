import 'package:belluga_now/domain/partners/account_profile_model.dart';
import 'package:belluga_now/domain/partners/projections/partner_profile_config.dart';
import 'package:belluga_now/domain/partners/projections/partner_profile_module_data.dart';
import 'package:belluga_now/domain/partners/paged_account_profiles_result.dart';
import 'package:belluga_now/domain/repositories/account_profiles_repository_contract.dart';
import 'package:belluga_now/domain/repositories/invites_repository_contract.dart';
import 'package:belluga_now/domain/repositories/user_events_repository_contract.dart';
import 'package:belluga_now/domain/repositories/value_objects/user_events_repository_contract_values.dart';
import 'package:belluga_now/domain/schedule/sent_invite_status.dart';
import 'package:belluga_now/domain/invites/invite_accept_result.dart';
import 'package:belluga_now/domain/invites/invite_decline_result.dart';
import 'package:belluga_now/domain/invites/invite_materialize_result.dart';
import 'package:belluga_now/domain/invites/invite_model.dart';
import 'package:belluga_now/domain/invites/invite_runtime_settings.dart';
import 'package:belluga_now/domain/invites/invite_share_code_result.dart';
import 'package:belluga_now/domain/invites/invite_contact_match.dart';
import 'package:belluga_now/presentation/tenant_public/partners/controllers/account_profile_detail_controller.dart';
import 'package:belluga_now/testing/account_profile_model_factory.dart';
import 'package:belluga_now/testing/domain_factories.dart';
import 'package:belluga_now/testing/invite_model_factory.dart';
import 'package:belluga_now/domain/venue_event/projections/venue_event_resume.dart';
import 'package:flutter_test/flutter_test.dart';
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
          startDateTime:
              DateTime.now().toUtc().subtract(const Duration(minutes: 45)),
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
  });

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
  });

  test('controller resolves invite status and distance for agenda cards',
      () async {
    final accountProfileRepository = _FakeAccountProfilesRepository();
    final userEventsRepository = _FakeUserEventsRepository(
      confirmedIds: const {'507f1f77bcf86cd799439031'},
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

    expect(controller.isEventConfirmed(event.eventId), isTrue);
    expect(controller.pendingInviteCount(event.eventId), 1);
    expect(controller.distanceLabelFor(profile, event), '752 m');
  });
}

class _FakeAccountProfilesRepository extends AccountProfilesRepositoryContract {
  _FakeAccountProfilesRepository() {
    favoriteAccountProfileIdsStreamValue.addValue(const {});
  }

  final List<AccountProfileModel> _profiles = <AccountProfileModel>[];

  @override
  Future<void> init() async {}

  @override
  Future<PagedAccountProfilesResult> fetchAccountProfilesPage({
    required AccountProfilesRepositoryContractPrimInt page,
    required AccountProfilesRepositoryContractPrimInt pageSize,
    AccountProfilesRepositoryContractPrimString? query,
    AccountProfilesRepositoryContractPrimString? typeFilter,
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
  }) async =>
      _profiles;

  @override
  Future<void> toggleFavorite(
    AccountProfilesRepositoryContractPrimString accountProfileId,
  ) async {}

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

class _FakeUserEventsRepository implements UserEventsRepositoryContract {
  _FakeUserEventsRepository({Set<String> confirmedIds = const {}})
      : _confirmedIds = Set<String>.from(confirmedIds) {
    confirmedEventIdsStream.addValue(
      _confirmedIds
          .map(
            (value) => userEventsRepoString(
              value,
              defaultValue: '',
              isRequired: true,
            ),
          )
          .toSet(),
    );
  }

  final Set<String> _confirmedIds;

  @override
  final confirmedEventIdsStream =
      StreamValue<Set<UserEventsRepositoryContractPrimString>>(
    defaultValue: const <UserEventsRepositoryContractPrimString>{},
  );

  @override
  Future<void> confirmEventAttendance(
    UserEventsRepositoryContractPrimString eventId,
  ) async {}

  @override
  Future<List<VenueEventResume>> fetchFeaturedEvents() async => const [];

  @override
  Future<List<VenueEventResume>> fetchMyEvents() async => const [];

  @override
  UserEventsRepositoryContractPrimBool isEventConfirmed(
    UserEventsRepositoryContractPrimString eventId,
  ) =>
      userEventsRepoBool(
        _confirmedIds.contains(eventId.value),
        defaultValue: false,
        isRequired: true,
      );

  @override
  Future<void> refreshConfirmedEventIds() async {}

  @override
  Future<void> unconfirmEventAttendance(
    UserEventsRepositoryContractPrimString eventId,
  ) async {}
}

class _FakeInvitesRepository extends InvitesRepositoryContract {
  _FakeInvitesRepository({List<InviteModel> invites = const []}) {
    pendingInvitesStreamValue.addValue(List<InviteModel>.from(invites));
  }

  @override
  Future<InviteAcceptResult> acceptInvite(
    InvitesRepositoryContractPrimString inviteId,
  ) async =>
      throw UnimplementedError();

  @override
  Future<InviteAcceptResult> acceptInviteByCode(
    InvitesRepositoryContractPrimString code,
  ) async =>
      throw UnimplementedError();

  @override
  Future<InviteShareCodeResult> createShareCode({
    required InvitesRepositoryContractPrimString eventId,
    InvitesRepositoryContractPrimString? occurrenceId,
    InvitesRepositoryContractPrimString? accountProfileId,
  }) async =>
      throw UnimplementedError();

  @override
  Future<InviteDeclineResult> declineInvite(
    InvitesRepositoryContractPrimString inviteId,
  ) async =>
      throw UnimplementedError();

  @override
  Future<List<InviteModel>> fetchInvites({
    InvitesRepositoryContractPrimInt? page,
    InvitesRepositoryContractPrimInt? pageSize,
  }) async =>
      pendingInvitesStreamValue.value;

  @override
  Future<InviteRuntimeSettings> fetchSettings() async =>
      buildInviteRuntimeSettings(
        tenantId: null,
        limits: const {},
        cooldowns: const {},
        overQuotaMessage: null,
      );

  @override
  Future<List<SentInviteStatus>> getSentInvitesForEvent(
    InvitesRepositoryContractPrimString eventId,
  ) async =>
      const <SentInviteStatus>[];

  @override
  Future<List<InviteContactMatch>> importContacts(
          InviteContacts contacts) async =>
      const <InviteContactMatch>[];

  @override
  Future<InviteMaterializeResult> materializeShareCode(
    InvitesRepositoryContractPrimString code,
  ) async =>
      throw UnimplementedError();

  @override
  Future<InviteModel?> previewShareCode(
    InvitesRepositoryContractPrimString code,
  ) async =>
      null;

  @override
  Future<void> sendInvites(
    InvitesRepositoryContractPrimString eventId,
    InviteRecipients recipients, {
    InvitesRepositoryContractPrimString? occurrenceId,
    InvitesRepositoryContractPrimString? message,
  }) async {}
}

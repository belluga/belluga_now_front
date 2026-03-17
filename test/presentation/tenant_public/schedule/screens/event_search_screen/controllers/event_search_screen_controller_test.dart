import 'dart:async';
import 'package:belluga_now/testing/invite_accept_result_builder.dart';

import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/domain/app_data/value_object/platform_type_value.dart';
import 'package:belluga_now/domain/contacts/contact_model.dart';
import 'package:belluga_now/domain/invites/invite_accept_result.dart';
import 'package:belluga_now/domain/invites/invite_contact_match.dart';
import 'package:belluga_now/domain/invites/invite_decline_result.dart';
import 'package:belluga_now/domain/invites/invite_model.dart';
import 'package:belluga_now/domain/invites/invite_next_step.dart';
import 'package:belluga_now/domain/invites/invite_runtime_settings.dart';
import 'package:belluga_now/domain/invites/invite_share_code_result.dart';
import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';
import 'package:belluga_now/domain/repositories/app_data_repository_contract.dart';
import 'package:belluga_now/domain/repositories/invites_repository_contract.dart';
import 'package:belluga_now/domain/repositories/schedule_repository_contract.dart';
import 'package:belluga_now/domain/repositories/user_events_repository_contract.dart';
import 'package:belluga_now/domain/repositories/user_location_repository_contract.dart';
import 'package:belluga_now/domain/schedule/event_delta_model.dart';
import 'package:belluga_now/domain/schedule/friend_resume.dart';
import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:belluga_now/domain/schedule/paged_events_result.dart';
import 'package:belluga_now/domain/schedule/schedule_summary_model.dart';
import 'package:belluga_now/domain/schedule/sent_invite_status.dart';
import 'package:belluga_now/domain/venue_event/projections/venue_event_resume.dart';
import 'package:belluga_now/presentation/tenant_public/schedule/screens/event_search_screen/controllers/event_search_screen_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stream_value/core/stream_value.dart';

void main() {
  testWidgets(
    'stream disconnect triggers deterministic page-1 rehydrate and reconnect',
    (tester) async {
      final scheduleRepository = _FakeScheduleRepository();
      final controller = EventSearchScreenController(
        scheduleRepository: scheduleRepository,
        userEventsRepository: _FakeUserEventsRepository(),
        invitesRepository: _FakeInvitesRepository(),
        userLocationRepository: _FakeUserLocationRepository(),
        appDataRepository: _FakeAppDataRepository(_buildAppData()),
      );

      await controller.init();
      final baselineFetchCalls = scheduleRepository.getEventsPageCallCount;
      final baselineWatchCalls = scheduleRepository.watchEventsStreamCallCount;

      scheduleRepository.emitDisconnectError();
      await tester.pump();

      expect(
        scheduleRepository.getEventsPageCallCount,
        greaterThanOrEqualTo(baselineFetchCalls + 1),
      );
      expect(scheduleRepository.lastRequestedPage, 1);

      await tester.pump(const Duration(seconds: 3));

      expect(
        scheduleRepository.watchEventsStreamCallCount,
        greaterThanOrEqualTo(baselineWatchCalls + 1),
      );
      expect(scheduleRepository.lastRequestedPage, 1);

      controller.onDispose();
      scheduleRepository.dispose();
    },
  );

  testWidgets(
    'initial loading is finalized when first page fetch fails',
    (tester) async {
      final scheduleRepository = _FakeScheduleRepository()
        ..failOnPageFetch = true;
      final controller = EventSearchScreenController(
        scheduleRepository: scheduleRepository,
        userEventsRepository: _FakeUserEventsRepository(),
        invitesRepository: _FakeInvitesRepository(),
        userLocationRepository: _FakeUserLocationRepository(),
        appDataRepository: _FakeAppDataRepository(_buildAppData()),
      );

      await controller.init();

      expect(controller.isInitialLoadingStreamValue.value, isFalse);
      expect(controller.displayedEventsStreamValue.value, isEmpty);

      controller.onDispose();
      scheduleRepository.dispose();
    },
  );

  testWidgets(
    'does not fetch or subscribe stream when effective origin is missing',
    (tester) async {
      final scheduleRepository = _FakeScheduleRepository();
      final controller = EventSearchScreenController(
        scheduleRepository: scheduleRepository,
        userEventsRepository: _FakeUserEventsRepository(),
        invitesRepository: _FakeInvitesRepository(),
        userLocationRepository: _FakeUserLocationRepository(),
        appDataRepository:
            _FakeAppDataRepository(_buildAppData(includeDefaultOrigin: false)),
      );

      await controller.init();

      expect(scheduleRepository.getEventsPageCallCount, 0);
      expect(scheduleRepository.watchEventsStreamCallCount, 0);
      expect(controller.isInitialLoadingStreamValue.value, isFalse);
      expect(controller.hasMoreStreamValue.value, isFalse);

      controller.onDispose();
      scheduleRepository.dispose();
    },
  );
}

AppData _buildAppData({bool includeDefaultOrigin = true}) {
  final mapUi = <String, dynamic>{
    'radius': {
      'min_km': 1,
      'default_km': 5,
      'max_km': 50,
    },
  };
  if (includeDefaultOrigin) {
    mapUi['default_origin'] = const {
      'lat': -20.671339,
      'lng': -40.495395,
      'label': 'Praia do Morro',
    };
  }

  final remoteData = {
    'name': 'Tenant Test',
    'type': 'tenant',
    'main_domain': 'https://tenant.test',
    'profile_types': const [
      {
        'type': 'artist',
        'label': 'Artist',
        'allowed_taxonomies': [],
        'capabilities': {
          'is_favoritable': true,
          'is_poi_enabled': false,
        },
      },
    ],
    'domains': const ['https://tenant.test'],
    'app_domains': const [],
    'theme_data_settings': const {
      'brightness_default': 'light',
      'primary_seed_color': '#FFFFFF',
      'secondary_seed_color': '#000000',
    },
    'tenant_id': 'tenant-1',
    'telemetry': const {'trackers': []},
    'telemetry_context': const {'location_freshness_minutes': 5},
    'firebase': null,
    'push': null,
    'settings': {
      'map_ui': mapUi,
    },
  };

  final localInfo = {
    'platformType': PlatformTypeValue()..parse('mobile'),
    'hostname': 'tenant.test',
    'href': 'https://tenant.test',
    'port': null,
    'device': 'test-device',
  };

  return AppData.fromInitialization(
      remoteData: remoteData, localInfo: localInfo);
}

class _FakeAppDataRepository implements AppDataRepositoryContract {
  _FakeAppDataRepository(this._appData)
      : maxRadiusMetersStreamValue =
            StreamValue<double>(defaultValue: _appData.mapRadiusMaxMeters);

  final AppData _appData;

  @override
  AppData get appData => _appData;

  @override
  Future<void> init() async {}

  @override
  final StreamValue<ThemeMode?> themeModeStreamValue =
      StreamValue<ThemeMode?>(defaultValue: ThemeMode.light);

  @override
  ThemeMode get themeMode => themeModeStreamValue.value ?? ThemeMode.light;

  @override
  Future<void> setThemeMode(ThemeMode mode) async {
    themeModeStreamValue.addValue(mode);
  }

  @override
  final StreamValue<double> maxRadiusMetersStreamValue;

  @override
  double get maxRadiusMeters => maxRadiusMetersStreamValue.value;

  @override
  Future<void> setMaxRadiusMeters(double meters) async {
    maxRadiusMetersStreamValue.addValue(meters);
  }
}

class _FakeScheduleRepository implements ScheduleRepositoryContract {
  _FakeScheduleRepository();

  int getEventsPageCallCount = 0;
  int watchEventsStreamCallCount = 0;
  int? lastRequestedPage;
  double? lastOriginLat;
  double? lastOriginLng;
  bool failOnPageFetch = false;

  final List<StreamController<EventDeltaModel>> _streamControllers = [];

  void emitDisconnectError() {
    if (_streamControllers.isEmpty) return;
    _streamControllers.last.addError(Exception('stream disconnected'));
  }

  void dispose() {
    for (final controller in _streamControllers) {
      controller.close();
    }
    _streamControllers.clear();
  }

  @override
  Future<List<EventModel>> getAllEvents() async => const [];

  @override
  Future<EventModel?> getEventBySlug(String slug) async => null;

  @override
  Future<List<EventModel>> getEventsByDate(
    DateTime date, {
    double? originLat,
    double? originLng,
    double? maxDistanceMeters,
  }) async =>
      const [];

  @override
  Future<PagedEventsResult> getEventsPage({
    required int page,
    required int pageSize,
    required bool showPastOnly,
    String searchQuery = '',
    List<String>? categories,
    List<String>? tags,
    List<Map<String, String>>? taxonomy,
    bool confirmedOnly = false,
    double? originLat,
    double? originLng,
    double? maxDistanceMeters,
  }) async {
    getEventsPageCallCount += 1;
    lastRequestedPage = page;
    lastOriginLat = originLat;
    lastOriginLng = originLng;
    if (failOnPageFetch) {
      throw Exception('forced first-page failure');
    }
    return const PagedEventsResult(events: [], hasMore: false);
  }

  @override
  Future<ScheduleSummaryModel> getScheduleSummary() async {
    throw UnimplementedError();
  }

  @override
  Future<List<VenueEventResume>> getEventResumesByDate(DateTime date) async =>
      const [];

  @override
  Future<List<VenueEventResume>> fetchUpcomingEvents() async => const [];

  @override
  Stream<EventDeltaModel> watchEventsStream({
    String searchQuery = '',
    List<String>? categories,
    List<String>? tags,
    List<Map<String, String>>? taxonomy,
    bool confirmedOnly = false,
    double? originLat,
    double? originLng,
    double? maxDistanceMeters,
    String? lastEventId,
    bool showPastOnly = false,
  }) {
    watchEventsStreamCallCount += 1;
    lastOriginLat = originLat;
    lastOriginLng = originLng;
    final controller = StreamController<EventDeltaModel>.broadcast();
    _streamControllers.add(controller);
    return controller.stream;
  }
}

class _FakeInvitesRepository extends InvitesRepositoryContract {
  @override
  Future<List<InviteModel>> fetchInvites(
          {int page = 1, int pageSize = 20}) async =>
      const [];

  @override
  Future<InviteRuntimeSettings> fetchSettings() async =>
      const InviteRuntimeSettings(
        tenantId: null,
        limits: {},
        cooldowns: {},
        overQuotaMessage: null,
      );

  @override
  Future<InviteAcceptResult> acceptInvite(String inviteId) async =>
      buildInviteAcceptResult(
        inviteId: inviteId,
        status: 'accepted',
        creditedAcceptance: true,
        attendancePolicy: 'free_confirmation_only',
        nextStep: InviteNextStep.freeConfirmationCreated,
        supersededInviteIds: const [],
      );

  @override
  Future<InviteDeclineResult> declineInvite(String inviteId) async =>
      InviteDeclineResult(
        inviteId: inviteId,
        status: 'declined',
        groupHasOtherPending: false,
      );

  @override
  Future<InviteAcceptResult> acceptShareCode(String code) async =>
      buildInviteAcceptResult(
        inviteId: code,
        status: 'accepted',
        creditedAcceptance: true,
        attendancePolicy: 'free_confirmation_only',
        nextStep: InviteNextStep.openAppToContinue,
        supersededInviteIds: const [],
      );

  @override
  Future<List<InviteContactMatch>> importContacts(
          List<ContactModel> contacts) async =>
      const [];

  @override
  Future<InviteShareCodeResult> createShareCode({
    required String eventId,
    String? occurrenceId,
    String? accountProfileId,
  }) async =>
      InviteShareCodeResult(
        code: 'CODE123',
        eventId: eventId,
        occurrenceId: occurrenceId,
      );

  @override
  Future<List<SentInviteStatus>> getSentInvitesForEvent(
      String eventSlug) async {
    return const [];
  }

  @override
  Future<void> sendInvites(
    String eventSlug,
    List<EventFriendResume> recipients, {
    String? occurrenceId,
    String? message,
  }) async {}
}

class _FakeUserEventsRepository implements UserEventsRepositoryContract {
  @override
  final StreamValue<Set<String>> confirmedEventIdsStream =
      StreamValue<Set<String>>(defaultValue: const {});

  @override
  Future<void> confirmEventAttendance(String eventId) async {}

  @override
  Future<List<VenueEventResume>> fetchFeaturedEvents() async => const [];

  @override
  Future<List<VenueEventResume>> fetchMyEvents() async => const [];

  @override
  bool isEventConfirmed(String eventId) => false;

  @override
  Future<void> unconfirmEventAttendance(String eventId) async {}

  @override
  Future<void> refreshConfirmedEventIds() async {}
}

class _FakeUserLocationRepository implements UserLocationRepositoryContract {
  @override
  final StreamValue<CityCoordinate?> userLocationStreamValue =
      StreamValue<CityCoordinate?>(defaultValue: null);

  @override
  final StreamValue<CityCoordinate?> lastKnownLocationStreamValue =
      StreamValue<CityCoordinate?>(defaultValue: null);

  @override
  final StreamValue<DateTime?> lastKnownCapturedAtStreamValue =
      StreamValue<DateTime?>(defaultValue: null);

  @override
  final StreamValue<double?> lastKnownAccuracyStreamValue =
      StreamValue<double?>(defaultValue: null);

  @override
  final StreamValue<String?> lastKnownAddressStreamValue =
      StreamValue<String?>(defaultValue: null);

  @override
  Future<void> ensureLoaded() async {}

  @override
  Future<void> setLastKnownAddress(String? address) async {
    lastKnownAddressStreamValue.addValue(address);
  }

  @override
  Future<bool> warmUpIfPermitted() async => false;

  @override
  Future<bool> refreshIfPermitted({
    Duration minInterval = const Duration(seconds: 30),
  }) async =>
      false;

  @override
  Future<String?> resolveUserLocation() async => null;

  @override
  Future<bool> startTracking({
    LocationTrackingMode mode = LocationTrackingMode.mapForeground,
  }) async =>
      false;

  @override
  Future<void> stopTracking() async {}
}

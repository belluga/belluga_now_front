import 'package:belluga_now/domain/repositories/app_data_repository_contract.dart';
import 'package:belluga_now/domain/repositories/user_events_repository_contract.dart';
import 'package:belluga_now/domain/repositories/schedule_repository_contract.dart';
import 'package:belluga_now/domain/repositories/value_objects/user_events_repository_contract_values.dart';
import 'package:belluga_now/domain/value_objects/thumb_uri_value.dart';
import 'package:belluga_now/domain/venue_event/projections/venue_event_resume.dart';
import 'package:belluga_now/infrastructure/dal/dao/laravel_backend/user_events_backend/laravel_user_events_backend.dart';
import 'package:belluga_now/infrastructure/services/user_events_backend_contract.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value.dart';

/// Implementation of UserEventsRepositoryContract
/// Uses backend-authoritative attendance commitments for confirmation state.
class UserEventsRepository implements UserEventsRepositoryContract {
  static final Uri _localEventPlaceholderUri =
      Uri.parse('asset://event-placeholder');
  static const int _myEventsPageSize = 10;
  static const int _maxMyEventsPages = 30;

  UserEventsRepository({
    ScheduleRepositoryContract? scheduleRepository,
    UserEventsBackendContract? backend,
    AppDataRepositoryContract? appDataRepository,
  })  : _scheduleRepository =
            scheduleRepository ?? GetIt.I.get<ScheduleRepositoryContract>(),
        _backend = backend ?? LaravelUserEventsBackend(),
        _appDataRepository = appDataRepository;

  final ScheduleRepositoryContract _scheduleRepository;
  final UserEventsBackendContract _backend;
  AppDataRepositoryContract? _appDataRepository;

  AppDataRepositoryContract? get _resolvedAppDataRepository {
    if (_appDataRepository != null) {
      return _appDataRepository;
    }
    if (!GetIt.I.isRegistered<AppDataRepositoryContract>()) {
      return null;
    }
    _appDataRepository = GetIt.I.get<AppDataRepositoryContract>();
    return _appDataRepository;
  }

  ThumbUriValue _resolveDefaultEventImage() {
    final configured =
        _resolvedAppDataRepository?.appData.mainLogoDarkUrl.value;
    final resolvedUri =
        (configured != null && configured.toString().trim().isNotEmpty)
            ? configured
            : _localEventPlaceholderUri;
    final thumbUriValue =
        ThumbUriValue(defaultValue: resolvedUri, isRequired: true)
          ..parse(resolvedUri.toString());
    return thumbUriValue;
  }

  /// Stream of confirmed event IDs
  @override
  final StreamValue<Set<UserEventsRepositoryContractPrimString>>
      confirmedEventIdsStream =
      StreamValue<Set<UserEventsRepositoryContractPrimString>>(
    defaultValue: const <UserEventsRepositoryContractPrimString>{},
  );

  /// In-memory storage for confirmed event IDs
  /// We use the stream value as the source of truth
  Set<UserEventsRepositoryContractPrimString> get _confirmedEventIds =>
      confirmedEventIdsStream.value;

  @override
  Future<void> refreshConfirmedEventIds() async {
    final response = await _backend.fetchConfirmedEventIds();
    final eventIdsRaw = response['confirmed_event_ids'];
    if (eventIdsRaw is! List) {
      confirmedEventIdsStream.addValue(
        const <UserEventsRepositoryContractPrimString>{},
      );
      return;
    }

    final next = eventIdsRaw
        .map(
          (item) => userEventsRepoString(
            item,
            defaultValue: '',
            isRequired: true,
          ),
        )
        .where((value) => value.value.isNotEmpty)
        .toSet();
    confirmedEventIdsStream.addValue(next);
  }

  @override
  Future<List<VenueEventResume>> fetchMyEvents() async {
    final events = <VenueEventResume>[];
    var currentPage = 1;
    var hasMore = true;
    final fallbackImage = _resolveDefaultEventImage();

    while (hasMore && currentPage <= _maxMyEventsPages) {
      final page = await _scheduleRepository.getEventsPage(
        page: ScheduleRepoInt.fromRaw(
          currentPage,
          defaultValue: 1,
        ),
        pageSize: ScheduleRepoInt.fromRaw(
          _myEventsPageSize,
          defaultValue: _myEventsPageSize,
        ),
        showPastOnly: ScheduleRepoBool.fromRaw(
          false,
          defaultValue: false,
        ),
        confirmedOnly: ScheduleRepoBool.fromRaw(
          true,
          defaultValue: true,
        ),
      );

      events.addAll(
        page.events.map(
          (event) => VenueEventResume.fromScheduleEvent(
            event,
            fallbackImage,
          ),
        ),
      );

      hasMore = page.hasMore;
      currentPage += 1;
    }

    return List<VenueEventResume>.unmodifiable(events);
  }

  @override
  Future<List<VenueEventResume>> fetchFeaturedEvents() async {
    return [];
  }

  @override
  Future<void> confirmEventAttendance(
    UserEventsRepositoryContractPrimString eventId,
  ) async {
    await _backend.confirmAttendance(eventId: eventId.value);
    await refreshConfirmedEventIds();
  }

  @override
  Future<void> unconfirmEventAttendance(
    UserEventsRepositoryContractPrimString eventId,
  ) async {
    await _backend.unconfirmAttendance(eventId: eventId.value);
    await refreshConfirmedEventIds();
  }

  @override
  UserEventsRepositoryContractPrimBool isEventConfirmed(
    UserEventsRepositoryContractPrimString eventId,
  ) {
    final normalized = eventId.value;
    final isConfirmed = _confirmedEventIds.any(
      (confirmed) => confirmed.value == normalized,
    );
    return userEventsRepoBool(
      isConfirmed,
      defaultValue: false,
      isRequired: true,
    );
  }
}

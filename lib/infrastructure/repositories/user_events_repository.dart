import 'package:belluga_now/domain/repositories/app_data_repository_contract.dart';
import 'package:belluga_now/domain/repositories/auth_repository_contract.dart';
import 'package:belluga_now/domain/repositories/invites_repository_contract.dart';
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

  UserEventsRepository({
    ScheduleRepositoryContract? scheduleRepository,
    UserEventsBackendContract? backend,
    AppDataRepositoryContract? appDataRepository,
    AuthRepositoryContract? authRepository,
    InvitesRepositoryContract Function()? invitesRepositoryResolver,
  })  : _scheduleRepository =
            scheduleRepository ?? GetIt.I.get<ScheduleRepositoryContract>(),
        _backend = backend ?? LaravelUserEventsBackend(),
        _appDataRepository = appDataRepository,
        _authRepository = authRepository,
        _invitesRepositoryResolver = invitesRepositoryResolver;

  final ScheduleRepositoryContract _scheduleRepository;
  final UserEventsBackendContract _backend;
  AppDataRepositoryContract? _appDataRepository;
  AuthRepositoryContract? _authRepository;
  final InvitesRepositoryContract Function()? _invitesRepositoryResolver;
  InvitesRepositoryContract? _invitesRepository;

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

  AuthRepositoryContract? get _resolvedAuthRepository {
    if (_authRepository != null) {
      return _authRepository;
    }
    if (!GetIt.I.isRegistered<AuthRepositoryContract>()) {
      return null;
    }
    _authRepository = GetIt.I.get<AuthRepositoryContract>();
    return _authRepository;
  }

  InvitesRepositoryContract? get _resolvedInvitesRepository {
    if (_invitesRepository != null) {
      return _invitesRepository;
    }
    final resolver = _invitesRepositoryResolver;
    if (resolver != null) {
      _invitesRepository = resolver.call();
      return _invitesRepository;
    }
    if (!GetIt.I.isRegistered<InvitesRepositoryContract>()) {
      return null;
    }
    _invitesRepository = GetIt.I.get<InvitesRepositoryContract>();
    return _invitesRepository;
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

  /// Stream of confirmed occurrence IDs.
  @override
  final StreamValue<Set<UserEventsRepositoryContractPrimString>>
      confirmedOccurrenceIdsStream =
      StreamValue<Set<UserEventsRepositoryContractPrimString>>(
    defaultValue: const <UserEventsRepositoryContractPrimString>{},
  );

  /// In-memory storage for confirmed occurrence IDs.
  /// We use the stream value as the source of truth
  Set<UserEventsRepositoryContractPrimString> get _confirmedOccurrenceIds =>
      confirmedOccurrenceIdsStream.value;

  @override
  Future<void> refreshConfirmedOccurrenceIds() async {
    final response = await _backend.fetchConfirmedOccurrenceIds();
    final occurrenceIdsRaw = response['confirmed_occurrence_ids'];
    if (occurrenceIdsRaw is! List) {
      throw StateError(
        'User events response missing confirmed_occurrence_ids.',
      );
    }

    final next = occurrenceIdsRaw
        .map(
          (item) => userEventsRepoString(
            item,
            defaultValue: '',
            isRequired: true,
          ),
        )
        .where((value) => value.value.isNotEmpty)
        .toSet();
    confirmedOccurrenceIdsStream.addValue(next);
  }

  @override
  Future<List<VenueEventResume>> fetchMyEvents() async {
    final authRepository = _resolvedAuthRepository;
    if (authRepository != null && !authRepository.isAuthorized) {
      return const <VenueEventResume>[];
    }

    final fallbackImage = _resolveDefaultEventImage();
    final events = await _scheduleRepository.loadConfirmedEvents(
      showPastOnly: ScheduleRepoBool.fromRaw(
        false,
        defaultValue: false,
      ),
    );
    return List<VenueEventResume>.unmodifiable(
      events.map(
        (event) => VenueEventResume.fromScheduleEvent(
          event,
          fallbackImage,
        ),
      ),
    );
  }

  @override
  Future<List<VenueEventResume>> fetchFeaturedEvents() async {
    return [];
  }

  @override
  Future<void> confirmEventAttendance(
    UserEventsRepositoryContractPrimString eventId, {
    required UserEventsRepositoryContractPrimString occurrenceId,
  }) async {
    await _backend.confirmAttendance(
      eventId: eventId.value,
      occurrenceId: occurrenceId.value,
    );
    await refreshConfirmedOccurrenceIds();
    final invitesRepository = _resolvedInvitesRepository;
    if (invitesRepository != null) {
      invitesRepository.clearShareCodeSessionContext(
        occurrenceId: invitesRepoString(
          occurrenceId.value,
          defaultValue: '',
          isRequired: true,
        ),
      );
      await invitesRepository.refreshPendingInvites();
    }
  }

  @override
  Future<void> unconfirmEventAttendance(
    UserEventsRepositoryContractPrimString eventId, {
    required UserEventsRepositoryContractPrimString occurrenceId,
  }) async {
    await _backend.unconfirmAttendance(
      eventId: eventId.value,
      occurrenceId: occurrenceId.value,
    );
    await refreshConfirmedOccurrenceIds();
    await _resolvedInvitesRepository?.refreshPendingInvites();
  }

  @override
  UserEventsRepositoryContractPrimBool isOccurrenceConfirmed(
    UserEventsRepositoryContractPrimString occurrenceId,
  ) {
    final normalized = occurrenceId.value;
    final isConfirmed = _confirmedOccurrenceIds.any(
      (confirmed) => confirmed.value == normalized,
    );
    return userEventsRepoBool(
      isConfirmed,
      defaultValue: false,
      isRequired: true,
    );
  }
}

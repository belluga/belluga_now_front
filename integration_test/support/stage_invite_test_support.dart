import 'dart:async';
import 'dart:io';

import 'package:belluga_now/domain/repositories/app_data_repository_contract.dart';
import 'package:belluga_now/domain/repositories/auth_repository_contract.dart';
import 'package:belluga_now/domain/repositories/schedule_repository_contract.dart';
import 'package:belluga_now/domain/schedule/event_delta_model.dart';
import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:belluga_now/domain/schedule/paged_events_result.dart';
import 'package:belluga_now/domain/schedule/schedule_summary_model.dart';
import 'package:belluga_now/domain/venue_event/projections/venue_event_resume.dart';
import 'package:belluga_now/infrastructure/dal/dao/backend_context.dart';
import 'package:belluga_now/infrastructure/dal/dao/backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/local/app_data_local_info_source/app_data_local_info_source.dart';
import 'package:belluga_now/infrastructure/dal/dao/production_backend/production_backend.dart';
import 'package:belluga_now/infrastructure/repositories/app_data_repository.dart';
import 'package:belluga_now/infrastructure/repositories/auth_repository.dart';
import 'package:belluga_now/infrastructure/repositories/invites_repository.dart';
import 'package:belluga_now/infrastructure/repositories/user_events_repository.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:package_info_plus/package_info_plus.dart';

class StageInviteTestSupport {
  static const String _tenantUrl = String.fromEnvironment(
    'STAGE_TENANT_URL',
    defaultValue: '',
  );
  static const String _secret = String.fromEnvironment(
    'STAGE_INVITE_TEST_SUPPORT_SECRET',
    defaultValue: '',
  );
  static const String _packageName = String.fromEnvironment(
    'STAGE_INVITE_PACKAGE_NAME',
    defaultValue: 'com.guarappari.app',
  );
  static const bool _allowBadCertificates = bool.fromEnvironment(
    'STAGE_INVITE_ALLOW_BAD_CERTIFICATES',
    defaultValue: false,
  );

  static void ensureConfigured() {
    if (_tenantUrl.trim().isEmpty) {
      fail(
        'Missing STAGE_TENANT_URL. '
        'Stage invite compatibility tests require the live tenant URL.',
      );
    }
    if (_secret.trim().isEmpty) {
      fail(
        'Missing STAGE_INVITE_TEST_SUPPORT_SECRET. '
        'Stage invite compatibility tests require the stage test-support secret.',
      );
    }
  }

  static bool get isConfigured =>
      _tenantUrl.trim().isNotEmpty && _secret.trim().isNotEmpty;

  static String get tenantUrl => _tenantUrl.trim();
  static String get secret => _secret.trim();
  static String get packageName => _packageName.trim();
  static bool get allowBadCertificates => _allowBadCertificates;

  static HttpOverrides? _previousHttpOverrides;
  static bool _httpOverridesInstalled = false;

  static void installHttpOverridesIfNeeded() {
    if (!_allowBadCertificates || _httpOverridesInstalled) {
      return;
    }

    _previousHttpOverrides = HttpOverrides.current;
    HttpOverrides.global = _StageInviteBadCertificateHttpOverrides(
      _previousHttpOverrides,
    );
    _httpOverridesInstalled = true;
  }

  static void restoreHttpOverrides() {
    if (!_httpOverridesInstalled) {
      return;
    }

    HttpOverrides.global = _previousHttpOverrides;
    _previousHttpOverrides = null;
    _httpOverridesInstalled = false;
  }
}

class StageInviteFixture {
  StageInviteFixture({
    required this.runId,
    required this.shareCode,
    required this.eventId,
    required this.inviteUrl,
    required this.inviteeEmail,
    required this.inviteePassword,
    required this.signupName,
    required this.signupEmail,
    required this.signupPassword,
  });

  final String runId;
  final String shareCode;
  final String eventId;
  final String inviteUrl;
  final String inviteeEmail;
  final String inviteePassword;
  final String signupName;
  final String signupEmail;
  final String signupPassword;
}

class StageInviteState {
  StageInviteState({
    required this.runId,
    required this.scenario,
    required this.eventId,
    required this.shareCode,
    required this.invites,
    required this.attendance,
  });

  final String runId;
  final String scenario;
  final String eventId;
  final String shareCode;
  final List<StageInviteStateInvite> invites;
  final StageInviteAttendanceState? attendance;
}

class StageInviteStateInvite {
  StageInviteStateInvite({
    required this.inviteId,
    required this.receiverUserId,
    required this.status,
    required this.creditedAcceptance,
    required this.supersessionReason,
  });

  final String inviteId;
  final String receiverUserId;
  final String status;
  final bool creditedAcceptance;
  final String? supersessionReason;
}

class StageInviteAttendanceState {
  StageInviteAttendanceState({
    required this.status,
    required this.kind,
  });

  final String status;
  final String kind;
}

class StageInviteSupportClient {
  StageInviteSupportClient({
    Dio? dio,
    String? tenantUrl,
    String? secret,
  })  : _tenantUrl = tenantUrl ?? StageInviteTestSupport.tenantUrl,
        _secret = secret ?? StageInviteTestSupport.secret,
        _dio = dio ??
            _buildDio(
              baseUrl: tenantUrl ?? StageInviteTestSupport.tenantUrl,
              allowBadCertificates: StageInviteTestSupport.allowBadCertificates,
            );

  final Dio _dio;
  final String _tenantUrl;
  final String _secret;

  static Dio _buildDio({
    required String baseUrl,
    required bool allowBadCertificates,
  }) {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 30),
        headers: const {
          'Accept': 'application/json',
        },
      ),
    );

    if (allowBadCertificates) {
      dio.httpClientAdapter = IOHttpClientAdapter(
        createHttpClient: () {
          final client = HttpClient();
          client.badCertificateCallback = (_, __, ___) => true;
          return client;
        },
      );
    }

    return dio;
  }

  Future<StageInviteFixture> bootstrap({
    required String scenario,
  }) async {
    final runId =
        'stage-${DateTime.now().millisecondsSinceEpoch}-${scenario.replaceAll('_', '-')}';
    final payload = await _post(
      '/api/v1/test-support/invites/bootstrap',
      data: {
        'run_id': runId,
        'scenario': scenario,
      },
    );

    return StageInviteFixture(
      runId: payload['run_id']?.toString() ?? runId,
      shareCode: payload['share_code']?.toString() ?? '',
      eventId: payload['event_id']?.toString() ?? '',
      inviteUrl: payload['invite_url']?.toString() ?? '',
      inviteeEmail: payload['invitee']?['email']?.toString() ?? '',
      inviteePassword: payload['invitee']?['password']?.toString() ?? '',
      signupName: payload['signup_candidate']?['name']?.toString() ?? '',
      signupEmail: payload['signup_candidate']?['email']?.toString() ?? '',
      signupPassword:
          payload['signup_candidate']?['password']?.toString() ?? '',
    );
  }

  Future<StageInviteState> state(String runId) async {
    final payload = await _get('/api/v1/test-support/invites/state/$runId');
    return StageInviteState(
      runId: payload['run_id']?.toString() ?? '',
      scenario: payload['scenario']?.toString() ?? '',
      eventId: payload['event_id']?.toString() ?? '',
      shareCode: payload['share_code']?.toString() ?? '',
      invites: ((payload['invites'] as List?) ?? const [])
          .map((invite) => StageInviteStateInvite(
                inviteId: invite['invite_id']?.toString() ?? '',
                receiverUserId: invite['receiver_user_id']?.toString() ?? '',
                status: invite['status']?.toString() ?? '',
                creditedAcceptance: invite['credited_acceptance'] == true,
                supersessionReason: invite['supersession_reason']?.toString(),
              ))
          .toList(growable: false),
      attendance: payload['attendance'] is Map<String, dynamic>
          ? StageInviteAttendanceState(
              status: payload['attendance']['status']?.toString() ?? '',
              kind: payload['attendance']['kind']?.toString() ?? '',
            )
          : null,
    );
  }

  Future<void> cleanup(String runId) async {
    await _post(
      '/api/v1/test-support/invites/cleanup',
      data: {'run_id': runId},
    );
  }

  Future<Map<String, dynamic>> _get(String path) async {
    try {
      final response = await _dio.get(
        path,
        options: Options(headers: {'X-Test-Support-Key': _secret}),
      );
      return _normalize(response.data);
    } on DioException catch (error) {
      throw TestFailure(
        'Stage invite test-support GET failed '
        '[status=${error.response?.statusCode}] '
        '(${error.requestOptions.uri}): ${error.response?.data ?? error.message}',
      );
    }
  }

  Future<Map<String, dynamic>> _post(
    String path, {
    required Map<String, dynamic> data,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        options: Options(headers: {'X-Test-Support-Key': _secret}),
      );
      return _normalize(response.data);
    } on DioException catch (error) {
      throw TestFailure(
        'Stage invite test-support POST failed '
        '[status=${error.response?.statusCode}] '
        '(${error.requestOptions.uri}): ${error.response?.data ?? error.message}',
      );
    }
  }

  Map<String, dynamic> _normalize(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      return raw;
    }
    throw TestFailure(
      'Unexpected stage invite test-support payload shape from $_tenantUrl.',
    );
  }
}

class _StageInviteBadCertificateHttpOverrides extends HttpOverrides {
  _StageInviteBadCertificateHttpOverrides(this._delegate);

  final HttpOverrides? _delegate;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client =
        _delegate?.createHttpClient(context) ?? super.createHttpClient(context);
    client.badCertificateCallback = (_, __, ___) => true;
    return client;
  }
}

class StageInviteRuntime {
  StageInviteRuntime({
    required this.backend,
    required this.appDataRepository,
    required this.authRepository,
    required this.invitesRepository,
    required this.userEventsRepository,
  });

  final BackendContract backend;
  final AppDataRepository appDataRepository;
  final AuthRepository authRepository;
  final InvitesRepository invitesRepository;
  final UserEventsRepository userEventsRepository;
}

Future<StageInviteRuntime> createStageInviteRuntime() async {
  FlutterSecureStorage.setMockInitialValues({});
  PackageInfo.setMockInitialValues(
    appName: 'Belluga Stage Test',
    packageName: StageInviteTestSupport.packageName,
    version: '0.0.1',
    buildNumber: '1',
    buildSignature: 'stage-test',
  );

  await GetIt.I.reset(dispose: true);

  final backend = ProductionBackend();
  GetIt.I.registerSingleton<BackendContract>(backend);

  final appDataRepository = AppDataRepository(
    backendContract: backend,
    localInfoSource: AppDataLocalInfoSource(),
  );
  await appDataRepository.init();
  GetIt.I.registerSingleton<AppDataRepositoryContract>(appDataRepository);
  backend.setContext(BackendContext.fromAppData(appDataRepository.appData));

  final authRepository = AuthRepository();
  GetIt.I.registerSingleton<AuthRepositoryContract>(authRepository);

  final invitesRepository = InvitesRepository();
  final userEventsRepository = UserEventsRepository(
    scheduleRepository: _EmptyScheduleRepository(),
  );

  return StageInviteRuntime(
    backend: backend,
    appDataRepository: appDataRepository,
    authRepository: authRepository,
    invitesRepository: invitesRepository,
    userEventsRepository: userEventsRepository,
  );
}

Future<void> resetStageInviteRuntime() async {
  await GetIt.I.reset(dispose: true);
}

class _EmptyScheduleRepository implements ScheduleRepositoryContract {
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
    throw UnimplementedError();
  }

  @override
  Future<List<VenueEventResume>> getEventResumesByDate(DateTime date) async =>
      const [];

  @override
  Future<ScheduleSummaryModel> getScheduleSummary() async {
    throw UnimplementedError();
  }

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
  }) =>
      const Stream.empty();
}

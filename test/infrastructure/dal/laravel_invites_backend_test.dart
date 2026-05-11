import 'dart:convert';

import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/testing/app_data_test_factory.dart';
import 'package:belluga_now/domain/app_data/value_object/platform_type_value.dart';
import 'package:belluga_now/domain/repositories/auth_repository_contract.dart';
import 'package:belluga_now/domain/repositories/value_objects/auth_repository_contract_values.dart';
import 'package:belluga_now/domain/user/user_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/laravel_backend/invites_backend/laravel_invites_backend.dart';
import 'package:belluga_now/infrastructure/services/sse/sse_client.dart';
import 'package:belluga_now/infrastructure/services/sse/sse_message.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await GetIt.I.reset();
    GetIt.I.registerSingleton<AuthRepositoryContract<UserContract>>(
      _FakeAuthRepository(),
    );
    GetIt.I.registerSingleton<AppData>(_buildAppData());
  });

  tearDown(() async {
    await GetIt.I.reset();
  });

  test('fetchInvites bootstraps auth token when initially missing', () async {
    final authRepository = GetIt.I.get<AuthRepositoryContract<UserContract>>()
        as _FakeAuthRepository;
    authRepository.setUserToken(authRepoString(''));
    authRepository.tokenAfterInit = 'refreshed-token';

    final adapter = _RecordingAdapter(
      response: const {
        'data': {
          'invites': [],
          'has_more': false,
        },
      },
    );
    final dio = Dio()..httpClientAdapter = adapter;
    final backend = LaravelInvitesBackend(dio: dio);

    await backend.fetchInvites(page: 1, pageSize: 20);

    expect(authRepository.initCallCount, 1);
    expect(
      adapter.lastRequest?.headers['Authorization'],
      'Bearer refreshed-token',
    );
    expect(adapter.lastRequest?.uri.path, '/api/v1/invites');
  });

  test('watchInvitesStream forwards auth and last event id', () {
    final sseClient = _RecordingSseClient();
    final backend = LaravelInvitesBackend(
      dio: Dio()..httpClientAdapter = _RecordingAdapter(response: const {}),
      sseClient: sseClient,
    );

    backend.watchInvitesStream(lastEventId: 'cursor-1');

    expect(sseClient.lastUri?.path, '/api/v1/invites/stream');
    expect(sseClient.lastUri?.queryParameters['access_token'], 'test-token');
    expect(sseClient.lastUri?.queryParameters['last_event_id'], 'cursor-1');
    expect(sseClient.lastEventId, 'cursor-1');
    expect(sseClient.lastHeaders?['Authorization'], 'Bearer test-token');
  });

  test('watchInvitesStream decodes canonical upsert payload', () async {
    final sseClient = _RecordingSseClient(
      stream: Stream<SseMessage>.value(
        SseMessage(
          event: 'invite.upsert',
          id: '2026-05-09T10:00:00Z',
          data:
              '{"type":"invite.upsert","invite":{"target_ref":{"event_id":"event-1","occurrence_id":"occurrence-1"},"event_name":"Invite Event","event_date":"2099-01-01T20:00:00Z","event_image_url":"https://example.com/event.png","location":"Centro","host_name":"Belluga","message":"Bora?","tags":["music"],"attendance_policy":"free_confirmation_only","inviter_candidates":[{"invite_id":"invite-1","display_name":"Ana","status":"pending","principal_kind":"user","principal_id":"user-1"}]}}',
        ),
      ),
    );
    final backend = LaravelInvitesBackend(
      dio: Dio()..httpClientAdapter = _RecordingAdapter(response: const {}),
      sseClient: sseClient,
    );

    final delta = await backend.watchInvitesStream().first;

    expect(delta.isUpsert, isTrue);
    expect(delta.lastEventId, '2026-05-09T10:00:00Z');
    expect(delta.invite?.eventId, 'event-1');
    expect(delta.invite?.occurrenceId, 'occurrence-1');
  });

  test('watchInvitesStream decodes canonical delete payload', () async {
    final sseClient = _RecordingSseClient(
      stream: Stream<SseMessage>.value(
        SseMessage(
          event: 'invite.deleted',
          id: '2026-05-09T10:00:01Z',
          data:
              '{"type":"invite.deleted","target_ref":{"event_id":"event-1","occurrence_id":"occurrence-1"}}',
        ),
      ),
    );
    final backend = LaravelInvitesBackend(
      dio: Dio()..httpClientAdapter = _RecordingAdapter(response: const {}),
      sseClient: sseClient,
    );

    final delta = await backend.watchInvitesStream().first;

    expect(delta.isDeleted, isTrue);
    expect(delta.eventId, 'event-1');
    expect(delta.occurrenceId, 'occurrence-1');
  });
}

class _FakeAuthRepository extends AuthRepositoryContract<UserContract> {
  String _token = 'test-token';
  String? tokenAfterInit;
  int initCallCount = 0;

  @override
  BackendContract get backend => throw UnimplementedError();

  @override
  String get userToken => _token;

  @override
  void setUserToken(AuthRepositoryContractParamString? token) {
    _token = token?.value ?? '';
  }

  @override
  Future<String> getDeviceId() async => 'device-1';

  @override
  Future<String?> getUserId() async => 'user-1';

  @override
  bool get isUserLoggedIn => true;

  @override
  bool get isAuthorized => true;

  @override
  Future<void> init() async {
    initCallCount += 1;
    if (_token.trim().isEmpty &&
        tokenAfterInit != null &&
        tokenAfterInit!.trim().isNotEmpty) {
      _token = tokenAfterInit!;
    }
  }

  @override
  Future<void> autoLogin() async {}

  @override
  Future<void> loginWithEmailPassword(AuthRepositoryContractParamString email,
      AuthRepositoryContractParamString password) async {}

  @override
  Future<void> signUpWithEmailPassword(
    AuthRepositoryContractParamString name,
    AuthRepositoryContractParamString email,
    AuthRepositoryContractParamString password,
  ) async {}

  @override
  Future<void> sendTokenRecoveryPassword(
      AuthRepositoryContractParamString email,
      AuthRepositoryContractParamString codigoEnviado) async {}

  @override
  Future<void> logout() async {}

  @override
  Future<void> createNewPassword(
    AuthRepositoryContractParamString newPassword,
    AuthRepositoryContractParamString confirmPassword,
  ) async {}

  @override
  Future<void> sendPasswordResetEmail(
      AuthRepositoryContractParamString email) async {}

  @override
  Future<void> updateUser(
      UserCustomData data) async {}
}

class _RecordingAdapter implements HttpClientAdapter {
  _RecordingAdapter({required Map<String, dynamic> response})
      : _response = response;

  final Map<String, dynamic> _response;
  RequestOptions? lastRequest;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequest = options;
    return ResponseBody.fromString(
      jsonEncode(_response),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}

class _RecordingSseClient implements SseClient {
  _RecordingSseClient({
    Stream<SseMessage>? stream,
  }) : _stream = stream ?? const Stream<SseMessage>.empty();

  final Stream<SseMessage> _stream;
  Uri? lastUri;
  Map<String, String>? lastHeaders;
  String? lastEventId;

  @override
  Stream<SseMessage> connect(
    Uri uri, {
    Map<String, String>? headers,
    String? lastEventId,
  }) {
    lastUri = uri;
    lastHeaders = headers;
    this.lastEventId = lastEventId;
    return _stream;
  }
}

AppData _buildAppData() {
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
    'main_color': '#FFFFFF',
    'tenant_id': 'tenant-1',
    'telemetry': const {'trackers': []},
    'telemetry_context': const {'location_freshness_minutes': 5},
    'firebase': null,
    'push': null,
  };
  final localInfo = {
    'platformType': PlatformTypeValue()..parse('mobile'),
    'hostname': 'tenant.test',
    'href': 'https://tenant.test',
    'port': null,
    'device': 'test-device',
  };
  return buildAppDataFromInitialization(
    remoteData: remoteData,
    localInfo: localInfo,
  );
}

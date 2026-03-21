import 'dart:convert';

import 'package:belluga_now/domain/repositories/auth_repository_contract.dart';
import 'package:belluga_now/domain/repositories/landlord_auth_repository_contract.dart';
import 'package:belluga_now/domain/services/tenant_admin_tenant_scope_contract.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_event.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_term.dart';
import 'package:belluga_now/domain/user/user_contract.dart';
import 'package:belluga_now/infrastructure/repositories/tenant_admin/tenant_admin_events_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value.dart';

void main() {
  Future<void> registerAuth({
    required String landlordToken,
    required String accountToken,
  }) async {
    if (GetIt.I.isRegistered<LandlordAuthRepositoryContract>()) {
      GetIt.I.unregister<LandlordAuthRepositoryContract>();
    }
    if (GetIt.I.isRegistered<AuthRepositoryContract>()) {
      GetIt.I.unregister<AuthRepositoryContract>();
    }

    GetIt.I.registerSingleton<LandlordAuthRepositoryContract>(
      _StubAuthRepo(tokenValue: landlordToken),
    );
    GetIt.I.registerSingleton<AuthRepositoryContract>(
      _StubAccountAuthRepo(tokenValue: accountToken),
    );
  }

  setUp(() async {
    await GetIt.I.reset();
    await registerAuth(
      landlordToken: 'test-token',
      accountToken: 'account-token',
    );
  });

  tearDown(() async {
    await GetIt.I.reset();
  });

  test('createEvent persists taxonomy terms in payload', () async {
    final adapter = _EventsRoutingAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    final scope = _MutableTenantScope('https://tenant-a.test/admin/api');
    final repository = TenantAdminEventsRepository(
      dio: dio,
      tenantScope: scope,
    );

    final created = await repository.createEvent(
      draft: _buildDraft(
        taxonomyTerms: const [
          TenantAdminTaxonomyTerm(type: 'music_genre', value: 'rock'),
          TenantAdminTaxonomyTerm(type: 'audience', value: 'families'),
        ],
      ),
    );

    expect(adapter.requests, isNotEmpty);
    final request = adapter.requests.last;
    expect(request.method, 'POST');
    expect(request.path, endsWith('/admin/api/v1/events'));
    expect(request.data, isA<Map<String, dynamic>>());
    final payload = request.data as Map<String, dynamic>;
    expect(payload['taxonomy_terms'], isA<List<dynamic>>());
    final terms = payload['taxonomy_terms'] as List<dynamic>;
    expect(terms, hasLength(2));
    expect(
      terms,
      containsAll([
        {'type': 'music_genre', 'value': 'rock'},
        {'type': 'audience', 'value': 'families'},
      ]),
    );
    expect(created.taxonomyTerms.map((term) => term.type),
        contains('music_genre'));
  });

  test(
      'createEvent omits geo payload for online mode even when coordinates exist',
      () async {
    final adapter = _EventsRoutingAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    final scope = _MutableTenantScope('https://tenant-a.test/admin/api');
    final repository = TenantAdminEventsRepository(
      dio: dio,
      tenantScope: scope,
    );

    await repository.createEvent(
      draft: _buildDraft(
        location: const TenantAdminEventLocation(
          mode: 'online',
          latitude: -20.611121,
          longitude: -40.498617,
          online: TenantAdminEventOnlineLocation(
            url: 'https://example.com/live',
          ),
        ),
      ),
    );

    expect(adapter.requests, isNotEmpty);
    final request = adapter.requests.last;
    expect(request.method, 'POST');
    expect(request.path, endsWith('/admin/api/v1/events'));
    final payload = request.data as Map<String, dynamic>;
    final location = payload['location'] as Map<String, dynamic>;
    expect(location['mode'], 'online');
    expect(location.containsKey('geo'), isFalse);
    expect(location['online'], {'url': 'https://example.com/live'});
  });

  test('createOwnEvent uses account-scoped endpoint', () async {
    final adapter = _EventsRoutingAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    final scope = _MutableTenantScope('https://tenant-a.test/admin/api');
    final repository = TenantAdminEventsRepository(
      dio: dio,
      tenantScope: scope,
    );

    await repository.createOwnEvent(
      accountSlug: 'my-account',
      draft: _buildDraft(),
    );

    expect(adapter.requests, isNotEmpty);
    final request = adapter.requests.last;
    expect(request.method, 'POST');
    expect(request.path, endsWith('/api/v1/accounts/my-account/events'));
    expect(request.headers['Authorization'], 'Bearer account-token');
  });

  test('fetchEventsPage maps 404 into empty page result', () async {
    final adapter = _NotFoundEventsAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    final scope = _MutableTenantScope('https://tenant-a.test/admin/api');
    final repository = TenantAdminEventsRepository(
      dio: dio,
      tenantScope: scope,
    );

    final result = await repository.fetchEventsPage(
      page: 1,
      pageSize: 20,
    );

    expect(result.items, isEmpty);
    expect(result.hasMore, isFalse);
  });

  test('fetchEventsPage serializes archived filter as integer boolean', () async {
    final adapter = _EventsRoutingAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    final scope = _MutableTenantScope('https://tenant-a.test/admin/api');
    final repository = TenantAdminEventsRepository(
      dio: dio,
      tenantScope: scope,
    );

    await repository.fetchEventsPage(
      page: 1,
      pageSize: 20,
      archived: true,
    );

    final request = adapter.requests.lastWhere(
      (request) =>
          request.method == 'GET' &&
          request.path.endsWith('/admin/api/v1/events'),
    );
    expect(request.queryParameters['archived'], 1);
  });

  test('fetchEventTypes prefers landlord token and maps payload', () async {
    final adapter = _EventTypesAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    final scope = _MutableTenantScope('https://tenant-a.test/admin/api');
    final repository = TenantAdminEventsRepository(
      dio: dio,
      tenantScope: scope,
    );

    final eventTypes = await repository.fetchEventTypes();

    expect(eventTypes, hasLength(2));
    expect(eventTypes[0].id, '507f1f77bcf86cd799439011');
    expect(eventTypes[0].name, 'Show');
    expect(eventTypes[0].slug, 'show');
    expect(eventTypes[1].id, '507f1f77bcf86cd799439012');
    expect(eventTypes[1].name, 'Workshop');
    expect(eventTypes[1].slug, 'workshop');

    expect(adapter.requests, hasLength(1));
    final request = adapter.requests.first;
    expect(request.method, 'GET');
    expect(request.path, endsWith('/admin/api/v1/event_types'));
    expect(request.headers['Authorization'], 'Bearer test-token');
  });

  test('fetchEventTypes falls back to account token when landlord token empty',
      () async {
    await registerAuth(
      landlordToken: '',
      accountToken: 'account-token',
    );

    final adapter = _EventTypesAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    final scope = _MutableTenantScope('https://tenant-a.test/admin/api');
    final repository = TenantAdminEventsRepository(
      dio: dio,
      tenantScope: scope,
    );

    final eventTypes = await repository.fetchEventTypes();

    expect(eventTypes, hasLength(2));
    expect(adapter.requests, hasLength(1));
    final request = adapter.requests.first;
    expect(request.method, 'GET');
    expect(request.path, endsWith('/admin/api/v1/event_types'));
    expect(request.headers['Authorization'], 'Bearer account-token');
  });

  test('fetchEventTypes throws when both landlord and account token are empty',
      () async {
    await registerAuth(
      landlordToken: '',
      accountToken: '',
    );

    final adapter = _EventTypesAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    final scope = _MutableTenantScope('https://tenant-a.test/admin/api');
    final repository = TenantAdminEventsRepository(
      dio: dio,
      tenantScope: scope,
    );

    await expectLater(
      () => repository.fetchEventTypes(),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('Failed to resolve auth token for event types request.'),
        ),
      ),
    );
  });

  test('fetchPartyCandidates uses dedicated events candidates endpoint',
      () async {
    final adapter = _PartyCandidatesAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    final scope = _MutableTenantScope('https://tenant-a.test/admin/api');
    final repository = TenantAdminEventsRepository(
      dio: dio,
      tenantScope: scope,
    );

    final candidates = await repository.fetchPartyCandidates(search: 'main');

    expect(candidates.venues, hasLength(1));
    expect(candidates.venues.first.id, 'venue-1');
    expect(candidates.venues.first.profileType, 'venue');
    expect(candidates.artists, isEmpty);

    final candidateRequests = adapter.requests
        .where((request) =>
            request.path.endsWith('/admin/api/v1/events/party_candidates'))
        .toList(growable: false);

    expect(candidateRequests, hasLength(1));
    expect(candidateRequests.first.queryParameters['search'], 'main');
    expect(candidateRequests.first.queryParameters['limit'], 100);
    expect(
        candidateRequests.first.headers['Authorization'], 'Bearer test-token');
  });

  test('fetchPartyCandidates uses account-scoped endpoint for own-create flow',
      () async {
    final adapter = _PartyCandidatesAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    final scope = _MutableTenantScope('https://tenant-a.test/admin/api');
    final repository = TenantAdminEventsRepository(
      dio: dio,
      tenantScope: scope,
    );

    final candidates = await repository.fetchPartyCandidates(
      search: 'main',
      accountSlug: 'my-account',
    );

    expect(candidates.venues, hasLength(1));
    expect(candidates.venues.first.id, 'venue-1');
    expect(candidates.venues.first.profileType, 'venue');
    expect(candidates.artists, isEmpty);

    final candidateRequests = adapter.requests
        .where((request) => request.path
            .endsWith('/api/v1/accounts/my-account/events/party_candidates'))
        .toList(growable: false);

    expect(candidateRequests, hasLength(1));
    expect(candidateRequests.first.queryParameters['search'], 'main');
    expect(candidateRequests.first.queryParameters['limit'], 100);
    expect(candidateRequests.first.headers['Authorization'],
        'Bearer account-token');
  });

  test('fetchPartyCandidates throws when candidates endpoint is unauthorized',
      () async {
    final adapter = _UnauthorizedAdminPartyCandidatesAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    final scope = _MutableTenantScope('https://tenant-a.test/admin/api');
    final repository = TenantAdminEventsRepository(
      dio: dio,
      tenantScope: scope,
    );

    await expectLater(
      () => repository.fetchPartyCandidates(search: 'main'),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('Failed to load event party candidates'),
        ),
      ),
    );

    final candidateRequests = adapter.requests
        .where((request) =>
            request.path.endsWith('/admin/api/v1/events/party_candidates'))
        .toList(growable: false);
    expect(candidateRequests, hasLength(1));
  });

  test('fetchPartyCandidates throws when candidates endpoint is not found',
      () async {
    final adapter = _NotFoundAdminPartyCandidatesAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    final scope = _MutableTenantScope('https://tenant-a.test/admin/api');
    final repository = TenantAdminEventsRepository(
      dio: dio,
      tenantScope: scope,
    );

    await expectLater(
      () => repository.fetchPartyCandidates(search: 'main'),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          allOf(
            contains('Failed to load event party candidates'),
            contains('status=404'),
          ),
        ),
      ),
    );

    final candidateRequests = adapter.requests
        .where((request) =>
            request.path.endsWith('/admin/api/v1/events/party_candidates'))
        .toList(growable: false);
    expect(candidateRequests, hasLength(1));
  });

  test('updateEventType sends null description when value is cleared', () async {
    final adapter = _EventTypeMutationsAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    final scope = _MutableTenantScope('https://tenant-a.test/admin/api');
    final repository = TenantAdminEventsRepository(
      dio: dio,
      tenantScope: scope,
    );

    await repository.updateEventType(
      eventTypeId: '507f1f77bcf86cd799439011',
      name: 'Show',
      slug: 'show',
      description: null,
    );

    final request = adapter.requests.singleWhere(
      (candidate) =>
          candidate.method == 'PATCH' &&
          candidate.path.endsWith('/admin/api/v1/event_types/507f1f77bcf86cd799439011'),
    );

    expect(request.data, isA<Map<String, dynamic>>());
    final payload = request.data as Map<String, dynamic>;
    expect(payload['name'], 'Show');
    expect(payload['slug'], 'show');
    expect(payload.containsKey('description'), isTrue);
    expect(payload['description'], isNull);
  });
}

TenantAdminEventDraft _buildDraft({
  List<TenantAdminTaxonomyTerm> taxonomyTerms = const [],
  TenantAdminEventLocation? location,
}) {
  return TenantAdminEventDraft(
    title: 'My event',
    content: 'Content',
    type: const TenantAdminEventType(
      name: 'Show',
      slug: 'show',
    ),
    occurrences: [
      TenantAdminEventOccurrence(
        dateTimeStart: DateTime(2026, 3, 5, 20),
      ),
    ],
    publication: const TenantAdminEventPublication(
      status: 'draft',
    ),
    location: location,
    taxonomyTerms: taxonomyTerms,
  );
}

class _StubAuthRepo implements LandlordAuthRepositoryContract {
  _StubAuthRepo({required this.tokenValue});

  final String tokenValue;

  @override
  bool get hasValidSession => tokenValue.trim().isNotEmpty;

  @override
  String get token => tokenValue;

  @override
  Future<void> init() async {}

  @override
  Future<void> loginWithEmailPassword(String email, String password) async {}

  @override
  Future<void> logout() async {}
}

class _StubAccountAuthRepo implements AuthRepositoryContract<UserContract> {
  _StubAccountAuthRepo({required this.tokenValue});

  final String tokenValue;

  @override
  Object get backend => Object();

  @override
  final userStreamValue = StreamValue<UserContract?>();

  @override
  UserContract get user => throw UnimplementedError();

  @override
  String get userToken => tokenValue;

  @override
  void setUserToken(String? token) {}

  @override
  Future<String> getDeviceId() async => 'device-id';

  @override
  Future<String?> getUserId() async => 'user-1';

  @override
  bool get isUserLoggedIn => true;

  @override
  bool get isAuthorized => true;

  @override
  Future<void> init() async {}

  @override
  Future<void> autoLogin() async {}

  @override
  Future<void> loginWithEmailPassword(String email, String password) async {}

  @override
  Future<void> signUpWithEmailPassword(
    String name,
    String email,
    String password,
  ) async {}

  @override
  Future<void> sendTokenRecoveryPassword(
    String email,
    String codigoEnviado,
  ) async {}

  @override
  Future<void> logout() async {}

  @override
  Future<void> createNewPassword(
    String newPassword,
    String confirmPassword,
  ) async {}

  @override
  Future<void> sendPasswordResetEmail(String email) async {}

  @override
  Future<void> updateUser(Map<String, Object?> data) async {}
}

class _MutableTenantScope implements TenantAdminTenantScopeContract {
  _MutableTenantScope(String initialBaseUrl) {
    _selectedTenantDomainStreamValue.addValue(initialBaseUrl);
  }

  final StreamValue<String?> _selectedTenantDomainStreamValue =
      StreamValue<String?>(defaultValue: null);

  @override
  String? get selectedTenantDomain => _selectedTenantDomainStreamValue.value;

  @override
  String get selectedTenantAdminBaseUrl => selectedTenantDomain ?? '';

  @override
  StreamValue<String?> get selectedTenantDomainStreamValue =>
      _selectedTenantDomainStreamValue;

  @override
  void clearSelectedTenantDomain() {
    _selectedTenantDomainStreamValue.addValue(null);
  }

  @override
  void selectTenantDomain(String tenantDomain) {
    _selectedTenantDomainStreamValue.addValue(tenantDomain.trim());
  }
}

class _EventsRoutingAdapter implements HttpClientAdapter {
  final List<RequestOptions> requests = <RequestOptions>[];

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    if (options.path.endsWith('/v1/events') &&
        (options.method == 'POST' || options.method == 'PATCH')) {
      final payload = options.data is Map<String, dynamic>
          ? options.data as Map<String, dynamic>
          : <String, dynamic>{};
      return _jsonResponse(
        {'data': _eventFromPayload(payload)},
      );
    }

    if (options.path.contains('/api/v1/accounts/') &&
        options.path.endsWith('/events') &&
        options.method == 'POST') {
      final payload = options.data is Map<String, dynamic>
          ? options.data as Map<String, dynamic>
          : <String, dynamic>{};
      return _jsonResponse(
        {'data': _eventFromPayload(payload)},
      );
    }

    if (options.path.endsWith('/v1/events') && options.method == 'GET') {
      return _jsonResponse({
        'data': const [],
        'current_page': 1,
        'last_page': 1,
      });
    }

    return _jsonResponse({'data': const {}});
  }

  Map<String, dynamic> _eventFromPayload(Map<String, dynamic> payload) {
    return {
      'event_id': 'evt-1',
      'slug': 'my-event',
      'title': payload['title'] ?? 'My event',
      'content': payload['content'] ?? 'Content',
      'type': payload['type'] ??
          {
            'name': 'Show',
            'slug': 'show',
          },
      'date_time_start': '2026-03-05T20:00:00Z',
      'publication': payload['publication'] ?? {'status': 'draft'},
      'taxonomy_terms': payload['taxonomy_terms'] ?? const [],
      'occurrences': payload['occurrences'] ??
          const [
            {'date_time_start': '2026-03-05T20:00:00Z'}
          ],
    };
  }

  ResponseBody _jsonResponse(Map<String, dynamic> payload) {
    return ResponseBody.fromString(
      jsonEncode(payload),
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }
}

class _NotFoundEventsAdapter implements HttpClientAdapter {
  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.path.endsWith('/admin/api/v1/events') &&
        options.method == 'GET') {
      return ResponseBody.fromString(
        jsonEncode({'message': 'No events found'}),
        404,
        headers: {
          Headers.contentTypeHeader: ['application/json'],
        },
      );
    }

    return ResponseBody.fromString(
      jsonEncode({'data': const []}),
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }
}

class _EventTypesAdapter implements HttpClientAdapter {
  final List<RequestOptions> requests = <RequestOptions>[];

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);

    if (options.path.endsWith('/admin/api/v1/event_types') &&
        options.method == 'GET') {
      return ResponseBody.fromString(
        jsonEncode({
          'data': const [
            {
              'id': '507f1f77bcf86cd799439011',
              'name': 'Show',
              'slug': 'show',
              'description': 'Tipo de evento: Show',
            },
            {
              'id': '507f1f77bcf86cd799439012',
              'name': 'Workshop',
              'slug': 'workshop',
              'description': 'Tipo de evento: Workshop',
            },
          ],
        }),
        200,
        headers: {
          Headers.contentTypeHeader: ['application/json'],
        },
      );
    }

    return ResponseBody.fromString(
      jsonEncode({'data': const {}}),
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }
}

class _PartyCandidatesAdapter implements HttpClientAdapter {
  final List<RequestOptions> requests = <RequestOptions>[];

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);

    final isAdminCandidatesRequest =
        options.path.endsWith('/admin/api/v1/events/party_candidates') &&
            options.method == 'GET';
    final isAccountCandidatesRequest =
        options.path.endsWith('/events/party_candidates') &&
            options.path.contains('/api/v1/accounts/') &&
            options.method == 'GET';

    if (isAdminCandidatesRequest || isAccountCandidatesRequest) {
      final rawSearch = options.queryParameters['search']?.toString() ?? '';
      final search = rawSearch.trim().toLowerCase();
      final venueRows = <Map<String, dynamic>>[
        {
          'id': 'venue-1',
          'account_id': 'account-1',
          'profile_type': 'venue',
          'display_name': 'Main Venue',
          'slug': 'main-venue',
        },
        {
          'id': 'venue-legacy',
          'account_id': 'account-legacy',
          'profile_type': 'venue',
          'display_name': 'Main Legacy Venue',
          'slug': 'main-legacy-venue',
        },
      ];
      final artistRows = <Map<String, dynamic>>[
        {
          'id': 'artist-1',
          'account_id': 'account-2',
          'profile_type': 'artist',
          'display_name': 'DJ Night',
          'slug': 'dj-night',
        },
      ];
      return ResponseBody.fromString(
        jsonEncode({
          'data': {
            'physical_hosts': venueRows
                .where((row) =>
                    search.isEmpty ||
                    (row['display_name'] as String)
                        .toLowerCase()
                        .contains(search))
                .where((row) => row['id'] == 'venue-1')
                .toList(growable: false),
            'venues': venueRows
                .where((row) =>
                    search.isEmpty ||
                    (row['display_name'] as String)
                        .toLowerCase()
                        .contains(search))
                .toList(growable: false),
            'artists': artistRows
                .where((row) =>
                    search.isEmpty ||
                    (row['display_name'] as String)
                        .toLowerCase()
                        .contains(search))
                .toList(growable: false),
          },
        }),
        200,
        headers: {
          Headers.contentTypeHeader: ['application/json'],
        },
      );
    }

    if (options.path.endsWith('/admin/api/v1/events') &&
        options.method == 'GET') {
      return ResponseBody.fromString(
        jsonEncode({'data': const [], 'current_page': 1, 'last_page': 1}),
        200,
        headers: {
          Headers.contentTypeHeader: ['application/json'],
        },
      );
    }

    return ResponseBody.fromString(
      jsonEncode({'data': const {}}),
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }
}

class _EventTypeMutationsAdapter implements HttpClientAdapter {
  final List<RequestOptions> requests = <RequestOptions>[];

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);

    if (options.path.contains('/admin/api/v1/event_types/') &&
        options.method == 'PATCH') {
      return ResponseBody.fromString(
        jsonEncode({
          'data': {
            'id': '507f1f77bcf86cd799439011',
            'name': 'Show',
            'slug': 'show',
            'description': null,
          },
        }),
        200,
        headers: {
          Headers.contentTypeHeader: ['application/json'],
        },
      );
    }

    return ResponseBody.fromString(
      jsonEncode({'data': const {}}),
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }
}

class _UnauthorizedAdminPartyCandidatesAdapter implements HttpClientAdapter {
  final List<RequestOptions> requests = <RequestOptions>[];

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);

    if (options.path.endsWith('/admin/api/v1/events/party_candidates') &&
        options.method == 'GET') {
      return ResponseBody.fromString(
        jsonEncode({'message': 'Unauthorized.'}),
        403,
        headers: {
          Headers.contentTypeHeader: ['application/json'],
        },
      );
    }

    return ResponseBody.fromString(
      jsonEncode({'data': const []}),
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }
}

class _NotFoundAdminPartyCandidatesAdapter implements HttpClientAdapter {
  final List<RequestOptions> requests = <RequestOptions>[];

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);

    if (options.path.endsWith('/admin/api/v1/events/party_candidates') &&
        options.method == 'GET') {
      return ResponseBody.fromString(
        jsonEncode({'message': 'Not found.'}),
        404,
        headers: {
          Headers.contentTypeHeader: ['application/json'],
        },
      );
    }

    return ResponseBody.fromString(
      jsonEncode({'data': const []}),
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }
}

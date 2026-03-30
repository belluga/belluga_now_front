import 'dart:convert';

import 'package:belluga_now/domain/map/queries/poi_query.dart';
import 'package:belluga_now/domain/map/value_objects/poi_filter_key_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_filter_source_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_filter_taxonomy_token_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_filter_type_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_tag_value.dart';
import 'package:belluga_now/domain/repositories/auth_repository_contract.dart';
import 'package:belluga_now/domain/repositories/value_objects/auth_repository_contract_values.dart';
import 'package:belluga_now/domain/user/user_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/backend_context.dart';
import 'package:belluga_now/infrastructure/dal/dao/laravel_backend/map/laravel_map_poi_http_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await GetIt.I.reset();
    GetIt.I.registerSingleton<AuthRepositoryContract>(_FakeAuthRepository());
  });

  tearDown(() async {
    await GetIt.I.reset();
  });

  test(
      'getPois sends authenticated array query params with Laravel-compatible encoding',
      () async {
    final adapter = _RecordingAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    final service = LaravelMapPoiHttpService(
      context: BackendContext(
        baseUrl: 'https://tenant.test/api',
        adminUrl: 'https://tenant.test/admin/api',
      ),
      dio: dio,
    );

    await service.getPois(
      _buildPoiQuery(
        source: 'static_asset',
        categoryKeys: <String>{'beach'},
        types: <String>{'beach_spot'},
        tags: <String>{'family'},
        taxonomy: <String>{'cuisine:italian'},
      ),
    );

    final request = adapter.requests.single;
    expect(request.path, '/v1/map/pois');
    expect(request.headers['Accept'], 'application/json');
    expect(request.headers['Authorization'], 'Bearer test-token');
    expect(
      request.uri.toString(),
      contains('categories%5B%5D=beach'),
    );
    expect(
      request.uri.toString(),
      contains('types%5B%5D=beach_spot'),
    );
    expect(
      request.uri.toString(),
      contains('tags%5B%5D=family'),
    );
    expect(
      request.uri.toString(),
      contains('taxonomy%5B%5D=cuisine%3Aitalian'),
    );
  });

  test(
      'getFilters keeps server-query arrays compatible with Laravel validation',
      () async {
    final adapter = _RecordingAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    final service = LaravelMapPoiHttpService(
      context: BackendContext(
        baseUrl: 'https://tenant.test/api',
        adminUrl: 'https://tenant.test/admin/api',
      ),
      dio: dio,
    );

    await service.getFilters(
      _buildPoiQuery(
        source: 'event',
        types: <String>{'showcase'},
      ),
    );

    final request = adapter.requests.single;
    expect(request.path, '/v1/map/filters');
    expect(request.headers['Accept'], 'application/json');
    expect(request.headers['Authorization'], 'Bearer test-token');
    expect(
      request.uri.toString(),
      contains('types%5B%5D=showcase'),
    );
  });

  test('getPois bootstraps auth token when initially missing', () async {
    final authRepository =
        GetIt.I.get<AuthRepositoryContract>() as _FakeAuthRepository;
    authRepository.setUserToken(authRepoString(''));
    authRepository.tokenAfterInit = 'refreshed-token';

    final adapter = _RecordingAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    final service = LaravelMapPoiHttpService(
      context: BackendContext(
        baseUrl: 'https://tenant.test/api',
        adminUrl: 'https://tenant.test/admin/api',
      ),
      dio: dio,
    );

    await service.getPois(PoiQuery());

    final request = adapter.requests.single;
    expect(authRepository.initCallCount, 1);
    expect(request.headers['Authorization'], 'Bearer refreshed-token');
  });

  test('getPois preserves icon visual contract from stacks payload', () async {
    final adapter = _PoiStacksAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    final service = LaravelMapPoiHttpService(
      context: BackendContext(
        baseUrl: 'https://tenant.test/api',
        adminUrl: 'https://tenant.test/admin/api',
      ),
      dio: dio,
    );

    final pois = await service.getPois(PoiQuery());

    expect(pois, hasLength(1));
    expect(pois.first.visual, isNotNull);
    expect(pois.first.visual?.mode, 'icon');
    expect(pois.first.visual?.icon, 'restaurant');
    expect(pois.first.visual?.color, '#EB2528');
    expect(pois.first.visual?.iconColor, '#101010');
  });
}

PoiQuery _buildPoiQuery({
  String? source,
  Set<String>? categoryKeys,
  Set<String>? types,
  Set<String>? tags,
  Set<String>? taxonomy,
}) {
  return PoiQuery(
    sourceValue: _buildSourceValue(source),
    categoryKeyValues:
        categoryKeys == null ? null : _buildFilterKeyValues(categoryKeys),
    typeValues: types == null ? null : _buildFilterTypeValues(types),
    tagValues: tags == null ? null : _buildTagValues(tags),
    taxonomyTokenValues:
        taxonomy == null ? null : _buildTaxonomyValues(taxonomy),
  );
}

PoiFilterSourceValue? _buildSourceValue(String? raw) {
  final normalized = raw?.trim().toLowerCase();
  if (normalized == null || normalized.isEmpty) {
    return null;
  }
  final value = PoiFilterSourceValue();
  value.parse(normalized);
  return value;
}

List<PoiFilterKeyValue> _buildFilterKeyValues(Iterable<String> rawValues) {
  final values = <PoiFilterKeyValue>[];
  for (final entry in rawValues) {
    final normalized = entry.trim().toLowerCase();
    if (normalized.isEmpty) {
      continue;
    }
    final value = PoiFilterKeyValue();
    value.parse(normalized);
    values.add(value);
  }
  return List<PoiFilterKeyValue>.unmodifiable(values.toSet().toList());
}

List<PoiFilterTypeValue> _buildFilterTypeValues(Iterable<String> rawValues) {
  final values = <PoiFilterTypeValue>[];
  for (final entry in rawValues) {
    final normalized = entry.trim().toLowerCase();
    if (normalized.isEmpty) {
      continue;
    }
    final value = PoiFilterTypeValue();
    value.parse(normalized);
    values.add(value);
  }
  return List<PoiFilterTypeValue>.unmodifiable(values.toSet().toList());
}

List<PoiTagValue> _buildTagValues(Iterable<String> rawValues) {
  final values = <PoiTagValue>[];
  for (final entry in rawValues) {
    final normalized = entry.trim().toLowerCase();
    if (normalized.isEmpty) {
      continue;
    }
    final value = PoiTagValue();
    value.parse(normalized);
    values.add(value);
  }
  return List<PoiTagValue>.unmodifiable(values.toSet().toList());
}

List<PoiFilterTaxonomyTokenValue> _buildTaxonomyValues(
  Iterable<String> rawValues,
) {
  final values = <PoiFilterTaxonomyTokenValue>[];
  for (final entry in rawValues) {
    final normalized = entry.trim().toLowerCase();
    if (normalized.isEmpty) {
      continue;
    }
    final value = PoiFilterTaxonomyTokenValue();
    value.parse(normalized);
    values.add(value);
  }
  return List<PoiFilterTaxonomyTokenValue>.unmodifiable(
    values.toSet().toList(),
  );
}

class _FakeAuthRepository extends AuthRepositoryContract<UserContract> {
  String _token = 'test-token';
  String? tokenAfterInit;
  int initCallCount = 0;

  @override
  Object get backend => Object();

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
  Future<void> createNewPassword(AuthRepositoryContractParamString newPassword,
      AuthRepositoryContractParamString confirmPassword) async {}

  @override
  Future<void> sendPasswordResetEmail(
      AuthRepositoryContractParamString email) async {}

  @override
  Future<void> updateUser(
      UserCustomData data) async {}
}

class _RecordingAdapter implements HttpClientAdapter {
  final List<RequestOptions> requests = [];

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final body = switch (options.path) {
      '/v1/map/filters' => <String, dynamic>{
          'categories': const <Object>[],
          'tags': const <Object>[],
          'taxonomy_terms': const <Object>[],
        },
      _ => <String, dynamic>{
          'stacks': const <Object>[],
        },
    };
    return ResponseBody.fromString(
      jsonEncode(body),
      200,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>[Headers.jsonContentType],
      },
    );
  }
}

class _PoiStacksAdapter implements HttpClientAdapter {
  final List<RequestOptions> requests = [];

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString(
      jsonEncode({
        'stacks': [
          {
            'stack_key': 'account_profile:poi-1',
            'stack_count': 1,
            'top_poi': {
              'id': 'poi-1',
              'title': 'Restaurante',
              'subtitle': 'Descricao',
              'description': 'Descricao',
              'address': 'Endereco',
              'category_slug': 'restaurant',
              'location': {
                'lat': -20.0,
                'lng': -40.0,
              },
              'visual': {
                'mode': {'value': 'icon'},
                'icon': {'value': 'restaurant'},
                'color': {'value': '#EB2528'},
                'icon_color': {'value': '#101010'},
                'source': {'value': 'type_definition'},
              },
            },
            'items': const <Object>[],
          },
        ],
      }),
      200,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>[Headers.jsonContentType],
      },
    );
  }
}

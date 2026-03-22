import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/domain/partners/account_profile_model.dart';
import 'package:belluga_now/domain/partners/paged_account_profiles_result.dart';
import 'package:belluga_now/infrastructure/dal/dao/account_profiles_backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/laravel_backend/shared/tenant_public_auth_headers.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

class LaravelAccountProfilesBackend implements AccountProfilesBackendContract {
  LaravelAccountProfilesBackend({Dio? dio}) : _dio = dio ?? Dio();

  static const int _defaultPageSize = 30;
  static const int _maxPages = 10;

  final Dio _dio;

  String get _apiBaseUrl =>
      '${GetIt.I.get<AppData>().mainDomainValue.value.origin}/api';

  Future<Map<String, String>> _buildHeaders({bool includeJsonAccept = false}) {
    return TenantPublicAuthHeaders.build(
      includeJsonAccept: includeJsonAccept,
      bootstrapIfEmpty: true,
    );
  }

  @override
  Future<List<AccountProfileModel>> fetchAccountProfiles() async {
    final page = await fetchAccountProfilesPage(
      page: 1,
      pageSize: _defaultPageSize,
    );

    return page.profiles;
  }

  @override
  Future<PagedAccountProfilesResult> fetchAccountProfilesPage({
    required int page,
    required int pageSize,
    String? query,
    String? typeFilter,
  }) async {
    try {
      final queryParameters = <String, dynamic>{
        'page': page,
        'per_page': pageSize,
      };
      final trimmedQuery = query?.trim();
      if (trimmedQuery != null && trimmedQuery.isNotEmpty) {
        queryParameters['search'] = trimmedQuery;
      }
      final trimmedType = typeFilter?.trim();
      if (trimmedType != null && trimmedType.isNotEmpty) {
        queryParameters['profile_type'] = trimmedType;
      }

      final headers = await _buildHeaders(includeJsonAccept: true);
      final response = await _dio.get(
        '$_apiBaseUrl/v1/account_profiles',
        queryParameters: queryParameters,
        options: Options(headers: headers),
      );
      final raw = response.data;
      if (raw is! Map<String, dynamic>) {
        throw Exception('Unexpected account profiles response shape.');
      }
      final data = raw['data'];
      if (data is! List) {
        throw Exception('Account profiles payload missing data list.');
      }

      final currentPage = _parsePageValue(raw['current_page']) ?? page;
      final lastPage = _parsePageValue(raw['last_page']);
      final hasMore = lastPage != null
          ? currentPage < lastPage
          : raw['next_page_url'] != null;

      return PagedAccountProfilesResult(
        profiles: _parseProfiles(data),
        hasMore: hasMore,
      );
    } on DioException catch (error) {
      final statusCode = error.response?.statusCode;
      final data = error.response?.data;
      throw Exception(
        'Failed to load account profiles '
        '[status=$statusCode] '
        '(${error.requestOptions.uri}): '
        '${data ?? error.message}',
      );
    }
  }

  @override
  Future<List<AccountProfileModel>> searchAccountProfiles({
    String? query,
    String? typeFilter,
  }) async {
    final profiles = <AccountProfileModel>[];
    var page = 1;
    var hasMore = true;

    while (hasMore && page <= _maxPages) {
      final result = await fetchAccountProfilesPage(
        page: page,
        pageSize: _defaultPageSize,
        query: query,
        typeFilter: typeFilter,
      );
      profiles.addAll(result.profiles);
      hasMore = result.hasMore;
      page += 1;
    }

    return profiles;
  }

  @override
  Future<AccountProfileModel?> fetchAccountProfileBySlug(String slug) async {
    final profiles = await fetchAccountProfiles();
    try {
      return profiles.firstWhere((profile) => profile.slug == slug);
    } catch (_) {
      return null;
    }
  }

  List<AccountProfileModel> _parseProfiles(List<dynamic> raw) {
    final profiles = <AccountProfileModel>[];
    for (final entry in raw) {
      if (entry is! Map) continue;
      final json = Map<String, dynamic>.from(entry);
      final id = json['id']?.toString();
      final name = json['display_name']?.toString();
      final slug = json['slug']?.toString();
      final typeRaw = json['profile_type']?.toString();
      if (id == null || name == null || slug == null || typeRaw == null) {
        continue;
      }
      final trimmedType = typeRaw.trim();
      if (trimmedType.isEmpty) continue;
      final tags = _extractTags(json['taxonomy_terms']);
      profiles.add(
        AccountProfileModel.fromPrimitives(
          id: id,
          name: name,
          slug: slug,
          type: trimmedType,
          avatarUrl: json['avatar_url']?.toString(),
          coverUrl: json['cover_url']?.toString(),
          bio: json['bio']?.toString(),
          tags: tags,
        ),
      );
    }
    return profiles;
  }

  List<String> _extractTags(dynamic raw) {
    if (raw is! List) return const [];
    final tags = <String>[];
    for (final entry in raw) {
      if (entry is Map) {
        final value = entry['value']?.toString();
        if (value != null && value.trim().isNotEmpty) {
          tags.add(value);
        }
      }
    }
    return tags;
  }

  int? _parsePageValue(dynamic raw) {
    if (raw is int) return raw;
    if (raw is String) return int.tryParse(raw);
    return null;
  }
}

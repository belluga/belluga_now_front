import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/domain/partners/account_profile_model.dart';
import 'package:belluga_now/domain/repositories/auth_repository_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/account_profiles_backend_contract.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

class LaravelAccountProfilesBackend implements AccountProfilesBackendContract {
  LaravelAccountProfilesBackend({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  String get _apiBaseUrl =>
      '${GetIt.I.get<AppData>().mainDomainValue.value.origin}/api';

  Map<String, String> _buildHeaders({bool includeJsonAccept = false}) {
    final token = GetIt.I.get<AuthRepositoryContract>().userToken;
    final headers = <String, String>{'Authorization': 'Bearer $token'};
    if (includeJsonAccept) {
      headers['Accept'] = 'application/json';
    }
    return headers;
  }

  @override
  Future<List<AccountProfileModel>> fetchAccountProfiles() async {
    try {
      final response = await _dio.get(
        '$_apiBaseUrl/v1/account_profiles',
        options: Options(headers: _buildHeaders(includeJsonAccept: true)),
      );
      final raw = response.data;
      if (raw is! Map<String, dynamic>) {
        throw Exception('Unexpected account profiles response shape.');
      }
      final data = raw['data'];
      if (data is! List) {
        throw Exception('Account profiles payload missing data list.');
      }
      return _parseProfiles(data);
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
    final partners = await fetchAccountProfiles();
    final trimmed = query?.trim().toLowerCase();
    var filtered = partners;
    if (typeFilter != null) {
      filtered =
          filtered.where((partner) => partner.profileType == typeFilter).toList();
    }
    if (trimmed != null && trimmed.isNotEmpty) {
      filtered = filtered.where((partner) {
        final nameMatch = partner.name.toLowerCase().contains(trimmed);
        final tagMatch = partner.tags
            .any((tag) => tag.toLowerCase().contains(trimmed));
        return nameMatch || tagMatch;
      }).toList();
    }
    return filtered;
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

}

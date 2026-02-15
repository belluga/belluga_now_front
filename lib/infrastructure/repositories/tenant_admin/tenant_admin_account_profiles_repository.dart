import 'package:belluga_now/domain/repositories/landlord_auth_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_account_profiles_repository_contract.dart';
import 'package:belluga_now/domain/services/tenant_admin_tenant_scope_contract.dart';
import 'package:belluga_now/domain/tenant_admin/ownership_state.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_location.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_media_upload.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_paged_result.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_profile_type.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_term.dart';
import 'package:belluga_now/infrastructure/dal/dto/tenant_admin/tenant_admin_account_profile_dto.dart';
import 'package:belluga_now/infrastructure/dal/dto/tenant_admin/tenant_admin_profile_type_dto.dart';
import 'package:belluga_now/infrastructure/repositories/tenant_admin/tenant_admin_pagination_utils.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:http_parser/http_parser.dart';

class TenantAdminAccountProfilesRepository
    implements TenantAdminAccountProfilesRepositoryContract {
  TenantAdminAccountProfilesRepository({
    Dio? dio,
    TenantAdminTenantScopeContract? tenantScope,
  })  : _dio = dio ?? Dio(),
        _tenantScope = tenantScope;

  final Dio _dio;
  final TenantAdminTenantScopeContract? _tenantScope;

  String get _apiBaseUrl =>
      (_tenantScope ?? GetIt.I.get<TenantAdminTenantScopeContract>())
          .selectedTenantAdminBaseUrl;

  Map<String, String> _buildHeaders() {
    final token = GetIt.I.get<LandlordAuthRepositoryContract>().token;
    return {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    };
  }

  @override
  Future<List<TenantAdminAccountProfile>> fetchAccountProfiles({
    String? accountId,
  }) async {
    try {
      final response = await _dio.get(
        '$_apiBaseUrl/v1/account_profiles',
        queryParameters: accountId == null ? null : {'account_id': accountId},
        options: Options(headers: _buildHeaders()),
      );
      final data = _extractList(response.data);
      return data.map(_mapProfile).toList(growable: false);
    } on DioException catch (error) {
      throw _wrapError(error, 'load account profiles');
    }
  }

  @override
  Future<TenantAdminAccountProfile> fetchAccountProfile(
    String accountProfileId,
  ) async {
    try {
      final response = await _dio.get(
        '$_apiBaseUrl/v1/account_profiles/$accountProfileId',
        options: Options(headers: _buildHeaders()),
      );
      final item = _extractItem(response.data);
      return _mapProfile(item);
    } on DioException catch (error) {
      throw _wrapError(error, 'load account profile');
    }
  }

  @override
  Future<TenantAdminAccountProfile> createAccountProfile({
    required String accountId,
    required String profileType,
    required String displayName,
    TenantAdminLocation? location,
    List<TenantAdminTaxonomyTerm> taxonomyTerms = const [],
    String? bio,
    String? avatarUrl,
    String? coverUrl,
    TenantAdminMediaUpload? avatarUpload,
    TenantAdminMediaUpload? coverUpload,
  }) async {
    try {
      final payload = <String, dynamic>{
        'account_id': accountId,
        'profile_type': profileType,
        'display_name': displayName,
        if (location != null)
          'location': {
            'lat': location.latitude,
            'lng': location.longitude,
          },
        if (taxonomyTerms.isNotEmpty)
          'taxonomy_terms': taxonomyTerms
              .map((term) => {'type': term.type, 'value': term.value})
              .toList(),
        if (bio != null) 'bio': bio,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
        if (coverUrl != null) 'cover_url': coverUrl,
      };
      final uploadPayload = _buildMultipartPayload(
        payload,
        avatarUpload: avatarUpload,
        coverUpload: coverUpload,
      );
      final response = await _dio.post(
        '$_apiBaseUrl/v1/account_profiles',
        data: uploadPayload ?? payload,
        options: Options(headers: _buildHeaders()),
      );
      final item = _extractItem(response.data);
      return _mapProfile(item);
    } on DioException catch (error) {
      throw _wrapError(error, 'create account profile');
    }
  }

  @override
  Future<TenantAdminAccountProfile> updateAccountProfile({
    required String accountProfileId,
    String? profileType,
    String? displayName,
    TenantAdminLocation? location,
    List<TenantAdminTaxonomyTerm>? taxonomyTerms,
    String? bio,
    String? avatarUrl,
    String? coverUrl,
    TenantAdminMediaUpload? avatarUpload,
    TenantAdminMediaUpload? coverUpload,
  }) async {
    try {
      final payload = <String, dynamic>{};
      if (profileType != null) payload['profile_type'] = profileType;
      if (displayName != null) payload['display_name'] = displayName;
      if (location != null) {
        payload['location'] = {
          'lat': location.latitude,
          'lng': location.longitude,
        };
      }
      if (taxonomyTerms != null) {
        payload['taxonomy_terms'] = taxonomyTerms
            .map((term) => {'type': term.type, 'value': term.value})
            .toList();
      }
      if (bio != null) payload['bio'] = bio;
      if (avatarUrl != null) payload['avatar_url'] = avatarUrl;
      if (coverUrl != null) payload['cover_url'] = coverUrl;
      final uploadPayload = _buildMultipartPayload(
        payload,
        avatarUpload: avatarUpload,
        coverUpload: coverUpload,
      );
      final response = uploadPayload == null
          ? await _dio.patch(
              '$_apiBaseUrl/v1/account_profiles/$accountProfileId',
              data: payload,
              options: Options(headers: _buildHeaders()),
            )
          : await _dio.post(
              '$_apiBaseUrl/v1/account_profiles/$accountProfileId',
              data: uploadPayload
                ..fields.add(const MapEntry('_method', 'PATCH')),
              options: Options(
                headers: _buildHeaders(),
                contentType: 'multipart/form-data',
              ),
            );
      final item = _extractItem(response.data);
      return _mapProfile(item);
    } on DioException catch (error) {
      throw _wrapError(error, 'update account profile');
    }
  }

  @override
  Future<void> deleteAccountProfile(String accountProfileId) async {
    try {
      await _dio.delete(
        '$_apiBaseUrl/v1/account_profiles/$accountProfileId',
        options: Options(headers: _buildHeaders()),
      );
    } on DioException catch (error) {
      throw _wrapError(error, 'delete account profile');
    }
  }

  @override
  Future<TenantAdminAccountProfile> restoreAccountProfile(
    String accountProfileId,
  ) async {
    try {
      final response = await _dio.post(
        '$_apiBaseUrl/v1/account_profiles/$accountProfileId/restore',
        options: Options(headers: _buildHeaders()),
      );
      final item = _extractItem(response.data);
      return _mapProfile(item);
    } on DioException catch (error) {
      throw _wrapError(error, 'restore account profile');
    }
  }

  @override
  Future<void> forceDeleteAccountProfile(String accountProfileId) async {
    try {
      await _dio.post(
        '$_apiBaseUrl/v1/account_profiles/$accountProfileId/force_delete',
        options: Options(headers: _buildHeaders()),
      );
    } on DioException catch (error) {
      throw _wrapError(error, 'force delete account profile');
    }
  }

  @override
  Future<List<TenantAdminProfileTypeDefinition>> fetchProfileTypes() async {
    var page = 1;
    const pageSize = 100;
    var hasMore = true;
    final types = <TenantAdminProfileTypeDefinition>[];

    while (hasMore) {
      final result = await fetchProfileTypesPage(
        page: page,
        pageSize: pageSize,
      );
      types.addAll(result.items);
      hasMore = result.hasMore;
      page += 1;
    }

    return List<TenantAdminProfileTypeDefinition>.unmodifiable(types);
  }

  @override
  Future<TenantAdminPagedResult<TenantAdminProfileTypeDefinition>>
      fetchProfileTypesPage({
    required int page,
    required int pageSize,
  }) async {
    try {
      final response = await _dio.get(
        '$_apiBaseUrl/v1/account_profile_types',
        queryParameters: {
          'page': page,
          'page_size': pageSize,
        },
        options: Options(headers: _buildHeaders()),
      );
      final data = _extractList(response.data);
      return TenantAdminPagedResult<TenantAdminProfileTypeDefinition>(
        items: data.map(_mapProfileType).toList(growable: false),
        hasMore: tenantAdminResolveHasMore(
          rawResponse: response.data,
          requestedPage: page,
        ),
      );
    } on DioException catch (error) {
      throw _wrapError(error, 'load profile types page');
    }
  }

  @override
  Future<TenantAdminProfileTypeDefinition> createProfileType({
    required String type,
    required String label,
    List<String> allowedTaxonomies = const [],
    required TenantAdminProfileTypeCapabilities capabilities,
  }) async {
    try {
      final response = await _dio.post(
        '$_apiBaseUrl/v1/account_profile_types',
        data: {
          'type': type,
          'label': label,
          'allowed_taxonomies': allowedTaxonomies,
          'capabilities': {
            'is_favoritable': capabilities.isFavoritable,
            'is_poi_enabled': capabilities.isPoiEnabled,
            'has_bio': capabilities.hasBio,
            'has_taxonomies': capabilities.hasTaxonomies,
            'has_avatar': capabilities.hasAvatar,
            'has_cover': capabilities.hasCover,
            'has_events': capabilities.hasEvents,
          },
        },
        options: Options(headers: _buildHeaders()),
      );
      final item = _extractItem(response.data);
      return _mapProfileType(item);
    } on DioException catch (error) {
      throw _wrapError(error, 'create profile type');
    }
  }

  @override
  Future<TenantAdminProfileTypeDefinition> updateProfileType({
    required String type,
    String? label,
    List<String>? allowedTaxonomies,
    TenantAdminProfileTypeCapabilities? capabilities,
  }) async {
    try {
      final encodedType = Uri.encodeComponent(type);
      final payload = <String, dynamic>{};
      if (label != null) {
        payload['label'] = label;
      }
      if (allowedTaxonomies != null) {
        payload['allowed_taxonomies'] = allowedTaxonomies;
      }
      if (capabilities != null) {
        payload['capabilities'] = {
          'is_favoritable': capabilities.isFavoritable,
          'is_poi_enabled': capabilities.isPoiEnabled,
          'has_bio': capabilities.hasBio,
          'has_taxonomies': capabilities.hasTaxonomies,
          'has_avatar': capabilities.hasAvatar,
          'has_cover': capabilities.hasCover,
          'has_events': capabilities.hasEvents,
        };
      }
      final response = await _dio.patch(
        '$_apiBaseUrl/v1/account_profile_types/$encodedType',
        data: payload,
        options: Options(headers: _buildHeaders()),
      );
      final item = _extractItem(response.data);
      return _mapProfileType(item);
    } on DioException catch (error) {
      throw _wrapError(error, 'update profile type');
    }
  }

  @override
  Future<void> deleteProfileType(String type) async {
    try {
      final encodedType = Uri.encodeComponent(type);
      await _dio.delete(
        '$_apiBaseUrl/v1/account_profile_types/$encodedType',
        options: Options(headers: _buildHeaders()),
      );
    } on DioException catch (error) {
      throw _wrapError(error, 'delete profile type');
    }
  }

  Map<String, dynamic> _extractItem(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      final data = raw['data'];
      if (data is Map<String, dynamic>) return data;
      return raw;
    }
    throw Exception('Unexpected account profile response shape.');
  }

  List<Map<String, dynamic>> _extractList(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      final data = raw['data'];
      if (data is List) {
        return data
            .whereType<Map>()
            .map((entry) => Map<String, dynamic>.from(entry))
            .toList();
      }
    }
    throw Exception('Unexpected account profiles list response shape.');
  }

  TenantAdminAccountProfile _mapProfile(Map<String, dynamic> json) {
    final dto = TenantAdminAccountProfileDTO.fromJson(json);
    final location = (dto.locationLat != null && dto.locationLng != null)
        ? TenantAdminLocation(
            latitude: dto.locationLat!,
            longitude: dto.locationLng!,
          )
        : null;
    final taxonomy = dto.taxonomyTerms
        .map((term) => TenantAdminTaxonomyTerm(
              type: term.type,
              value: term.value,
            ))
        .toList(growable: false);
    return TenantAdminAccountProfile(
      id: dto.id,
      accountId: dto.accountId,
      profileType: dto.profileType,
      displayName: dto.displayName,
      slug: dto.slug,
      avatarUrl: dto.avatarUrl,
      coverUrl: dto.coverUrl,
      bio: dto.bio,
      location: location,
      taxonomyTerms: taxonomy,
      ownershipState: dto.ownershipState == null
          ? null
          : TenantAdminOwnershipState.fromApiValue(dto.ownershipState),
    );
  }

  TenantAdminProfileTypeDefinition _mapProfileType(
    Map<String, dynamic> json,
  ) {
    final dto = TenantAdminProfileTypeDTO.fromJson(json);
    return TenantAdminProfileTypeDefinition(
      type: dto.type,
      label: dto.label,
      allowedTaxonomies: dto.allowedTaxonomies,
      capabilities: TenantAdminProfileTypeCapabilities(
        isFavoritable: dto.isFavoritable,
        isPoiEnabled: dto.isPoiEnabled,
        hasBio: dto.hasBio,
        hasTaxonomies: dto.hasTaxonomies,
        hasAvatar: dto.hasAvatar,
        hasCover: dto.hasCover,
        hasEvents: dto.hasEvents,
      ),
    );
  }

  FormData? _buildMultipartPayload(
    Map<String, dynamic> payload, {
    TenantAdminMediaUpload? avatarUpload,
    TenantAdminMediaUpload? coverUpload,
  }) {
    if (avatarUpload == null && coverUpload == null) {
      return null;
    }

    final formData = FormData.fromMap(payload, ListFormat.multiCompatible);
    if (avatarUpload != null) {
      formData.files.add(
        MapEntry(
          'avatar',
          MultipartFile.fromBytes(
            avatarUpload.bytes,
            filename: avatarUpload.fileName,
            contentType: _resolveMediaType(avatarUpload),
          ),
        ),
      );
    }
    if (coverUpload != null) {
      formData.files.add(
        MapEntry(
          'cover',
          MultipartFile.fromBytes(
            coverUpload.bytes,
            filename: coverUpload.fileName,
            contentType: _resolveMediaType(coverUpload),
          ),
        ),
      );
    }
    return formData;
  }

  MediaType _resolveMediaType(TenantAdminMediaUpload upload) {
    final mimeType = upload.mimeType ?? _inferMimeType(upload.fileName);
    if (mimeType == null) {
      return MediaType('application', 'octet-stream');
    }
    final parts = mimeType.split('/');
    if (parts.length != 2) {
      return MediaType('application', 'octet-stream');
    }
    return MediaType(parts[0], parts[1]);
  }

  String? _inferMimeType(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.webp')) return 'image/webp';
    return null;
  }

  Exception _wrapError(DioException error, String label) {
    final status = error.response?.statusCode;
    final data = error.response?.data;
    if (status == 422 && data is Map) {
      final message = data['message']?.toString().trim();
      final errors = data['errors'];
      final buffer = StringBuffer();
      if (message != null && message.isNotEmpty) {
        buffer.write(message);
      } else {
        buffer.write('Validation failed.');
      }
      if (errors is Map) {
        for (final entry in errors.entries) {
          final field = entry.key?.toString();
          final value = entry.value;
          if (field == null || field.isEmpty) continue;
          if (value is List && value.isNotEmpty) {
            buffer.write(' ');
            buffer.write('$field: ${value.first}');
          } else if (value != null) {
            buffer.write(' ');
            buffer.write('$field: $value');
          }
        }
      }
      return Exception(
        'Failed to $label [status=$status] (${error.requestOptions.uri}): '
        '${buffer.toString()}',
      );
    }
    return Exception(
      'Failed to $label [status=$status] (${error.requestOptions.uri}): '
      '${data ?? error.message}',
    );
  }
}

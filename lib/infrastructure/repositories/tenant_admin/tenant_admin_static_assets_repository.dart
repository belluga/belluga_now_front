import 'package:belluga_now/application/configurations/belluga_constants.dart';
import 'package:belluga_now/domain/repositories/landlord_auth_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_static_assets_repository_contract.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_location.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_media_upload.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_static_asset.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_static_profile_type.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_term.dart';
import 'package:belluga_now/infrastructure/dal/dto/tenant_admin/tenant_admin_static_asset_dto.dart';
import 'package:belluga_now/infrastructure/dal/dto/tenant_admin/tenant_admin_static_profile_type_dto.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:http_parser/http_parser.dart';

class TenantAdminStaticAssetsRepository
    implements TenantAdminStaticAssetsRepositoryContract {
  TenantAdminStaticAssetsRepository({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  String get _apiBaseUrl => BellugaConstants.api.adminUrl;

  Map<String, String> _buildHeaders() {
    final token = GetIt.I.get<LandlordAuthRepositoryContract>().token;
    return {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    };
  }

  @override
  Future<List<TenantAdminStaticAsset>> fetchStaticAssets() async {
    try {
      final response = await _dio.get(
        '$_apiBaseUrl/v1/static_assets',
        options: Options(headers: _buildHeaders()),
      );
      final data = _extractList(response.data);
      return data.map(_mapStaticAsset).toList(growable: false);
    } on DioException catch (error) {
      throw _wrapError(error, 'load static assets');
    }
  }

  @override
  Future<TenantAdminStaticAsset> fetchStaticAsset(String assetId) async {
    try {
      final response = await _dio.get(
        '$_apiBaseUrl/v1/static_assets/$assetId',
        options: Options(headers: _buildHeaders()),
      );
      final item = _extractItem(response.data);
      return _mapStaticAsset(item);
    } on DioException catch (error) {
      throw _wrapError(error, 'load static asset');
    }
  }

  @override
  Future<TenantAdminStaticAsset> createStaticAsset({
    required String profileType,
    required String displayName,
    required String slug,
    TenantAdminLocation? location,
    List<TenantAdminTaxonomyTerm> taxonomyTerms = const [],
    List<String> tags = const [],
    List<String> categories = const [],
    String? bio,
    String? content,
    String? avatarUrl,
    String? coverUrl,
    TenantAdminMediaUpload? avatarUpload,
    TenantAdminMediaUpload? coverUpload,
    required bool isActive,
  }) async {
    try {
      final payload = _buildPayload(
        profileType: profileType,
        displayName: displayName,
        slug: slug,
        location: location,
        taxonomyTerms: taxonomyTerms,
        tags: tags,
        categories: categories,
        bio: bio,
        content: content,
        avatarUrl: avatarUrl,
        coverUrl: coverUrl,
        isActive: isActive,
      );
      final uploadPayload = _buildMultipartPayload(
        payload,
        avatarUpload: avatarUpload,
        coverUpload: coverUpload,
      );
      final response = await _dio.post(
        '$_apiBaseUrl/v1/static_assets',
        data: uploadPayload ?? payload,
        options: Options(headers: _buildHeaders()),
      );
      final item = _extractItem(response.data);
      return _mapStaticAsset(item);
    } on DioException catch (error) {
      throw _wrapError(error, 'create static asset');
    }
  }

  @override
  Future<TenantAdminStaticAsset> updateStaticAsset({
    required String assetId,
    String? profileType,
    String? displayName,
    String? slug,
    TenantAdminLocation? location,
    List<TenantAdminTaxonomyTerm>? taxonomyTerms,
    List<String>? tags,
    List<String>? categories,
    String? bio,
    String? content,
    String? avatarUrl,
    String? coverUrl,
    TenantAdminMediaUpload? avatarUpload,
    TenantAdminMediaUpload? coverUpload,
    bool? isActive,
  }) async {
    try {
      final payload = _buildPayload(
        profileType: profileType,
        displayName: displayName,
        slug: slug,
        location: location,
        taxonomyTerms: taxonomyTerms,
        tags: tags,
        categories: categories,
        bio: bio,
        content: content,
        avatarUrl: avatarUrl,
        coverUrl: coverUrl,
        isActive: isActive,
      );
      final uploadPayload = _buildMultipartPayload(
        payload,
        avatarUpload: avatarUpload,
        coverUpload: coverUpload,
      );
      final response = uploadPayload == null
          ? await _dio.patch(
              '$_apiBaseUrl/v1/static_assets/$assetId',
              data: payload,
              options: Options(headers: _buildHeaders()),
            )
          : await _dio.post(
              '$_apiBaseUrl/v1/static_assets/$assetId',
              data: uploadPayload
                ..fields.add(const MapEntry('_method', 'PATCH')),
              options: Options(
                headers: _buildHeaders(),
                contentType: 'multipart/form-data',
              ),
            );
      final item = _extractItem(response.data);
      return _mapStaticAsset(item);
    } on DioException catch (error) {
      throw _wrapError(error, 'update static asset');
    }
  }

  @override
  Future<void> deleteStaticAsset(String assetId) async {
    try {
      await _dio.delete(
        '$_apiBaseUrl/v1/static_assets/$assetId',
        options: Options(headers: _buildHeaders()),
      );
    } on DioException catch (error) {
      throw _wrapError(error, 'delete static asset');
    }
  }

  @override
  Future<TenantAdminStaticAsset> restoreStaticAsset(String assetId) async {
    try {
      final response = await _dio.post(
        '$_apiBaseUrl/v1/static_assets/$assetId/restore',
        options: Options(headers: _buildHeaders()),
      );
      final item = _extractItem(response.data);
      return _mapStaticAsset(item);
    } on DioException catch (error) {
      throw _wrapError(error, 'restore static asset');
    }
  }

  @override
  Future<void> forceDeleteStaticAsset(String assetId) async {
    try {
      await _dio.delete(
        '$_apiBaseUrl/v1/static_assets/$assetId/force_delete',
        options: Options(headers: _buildHeaders()),
      );
    } on DioException catch (error) {
      throw _wrapError(error, 'force delete static asset');
    }
  }

  @override
  Future<List<TenantAdminStaticProfileTypeDefinition>>
      fetchStaticProfileTypes() async {
    try {
      final response = await _dio.get(
        '$_apiBaseUrl/v1/static_profile_types',
        options: Options(headers: _buildHeaders()),
      );
      final data = _extractList(response.data);
      return data.map(_mapStaticProfileType).toList(growable: false);
    } on DioException catch (error) {
      throw _wrapError(error, 'load static profile types');
    }
  }

  @override
  Future<TenantAdminStaticProfileTypeDefinition> createStaticProfileType({
    required String type,
    required String label,
    List<String> allowedTaxonomies = const [],
    required TenantAdminStaticProfileTypeCapabilities capabilities,
  }) async {
    try {
      final payload = _buildStaticProfileTypePayload(
        type: type,
        label: label,
        allowedTaxonomies: allowedTaxonomies,
        capabilities: capabilities,
      );
      final response = await _dio.post(
        '$_apiBaseUrl/v1/static_profile_types',
        data: payload,
        options: Options(headers: _buildHeaders()),
      );
      final item = _extractItem(response.data);
      return _mapStaticProfileType(item);
    } on DioException catch (error) {
      throw _wrapError(error, 'create static profile type');
    }
  }

  @override
  Future<TenantAdminStaticProfileTypeDefinition> updateStaticProfileType({
    required String type,
    String? label,
    List<String>? allowedTaxonomies,
    TenantAdminStaticProfileTypeCapabilities? capabilities,
  }) async {
    try {
      final encodedType = Uri.encodeComponent(type);
      final payload = _buildStaticProfileTypePayload(
        label: label,
        allowedTaxonomies: allowedTaxonomies,
        capabilities: capabilities,
      );
      final response = await _dio.patch(
        '$_apiBaseUrl/v1/static_profile_types/$encodedType',
        data: payload,
        options: Options(headers: _buildHeaders()),
      );
      final item = _extractItem(response.data);
      return _mapStaticProfileType(item);
    } on DioException catch (error) {
      throw _wrapError(error, 'update static profile type');
    }
  }

  @override
  Future<void> deleteStaticProfileType(String type) async {
    try {
      final encodedType = Uri.encodeComponent(type);
      await _dio.delete(
        '$_apiBaseUrl/v1/static_profile_types/$encodedType',
        options: Options(headers: _buildHeaders()),
      );
    } on DioException catch (error) {
      throw _wrapError(error, 'delete static profile type');
    }
  }

  Map<String, dynamic> _buildPayload({
    String? profileType,
    String? displayName,
    String? slug,
    TenantAdminLocation? location,
    List<TenantAdminTaxonomyTerm>? taxonomyTerms,
    List<String>? tags,
    List<String>? categories,
    String? bio,
    String? content,
    String? avatarUrl,
    String? coverUrl,
    bool? isActive,
  }) {
    final payload = <String, dynamic>{};
    if (profileType != null) payload['profile_type'] = profileType;
    if (displayName != null) payload['display_name'] = displayName;
    if (slug != null) payload['slug'] = slug;
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
    if (tags != null) payload['tags'] = tags;
    if (categories != null) payload['categories'] = categories;
    if (bio != null) payload['bio'] = bio;
    if (content != null) payload['content'] = content;
    if (avatarUrl != null) payload['avatar_url'] = avatarUrl;
    if (coverUrl != null) payload['cover_url'] = coverUrl;
    if (isActive != null) payload['is_active'] = isActive;
    return payload;
  }

  Map<String, dynamic> _extractItem(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      final data = raw['data'];
      if (data is Map<String, dynamic>) return data;
      return raw;
    }
    throw Exception('Unexpected static asset response shape.');
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
    throw Exception('Unexpected static assets list response shape.');
  }

  TenantAdminStaticAsset _mapStaticAsset(Map<String, dynamic> json) {
    final dto = TenantAdminStaticAssetDTO.fromJson(json);
    final location = (dto.locationLat != null && dto.locationLng != null)
        ? TenantAdminLocation(
            latitude: dto.locationLat!,
            longitude: dto.locationLng!,
          )
        : null;
    final taxonomy = dto.taxonomyTerms
        .map(
          (term) => TenantAdminTaxonomyTerm(
            type: term.type,
            value: term.value,
          ),
        )
        .toList(growable: false);
    return TenantAdminStaticAsset(
      id: dto.id,
      profileType: dto.profileType,
      displayName: dto.displayName,
      slug: dto.slug,
      avatarUrl: dto.avatarUrl,
      coverUrl: dto.coverUrl,
      bio: dto.bio,
      content: dto.content,
      tags: dto.tags,
      categories: dto.categories,
      taxonomyTerms: taxonomy,
      location: location,
      isActive: dto.isActive,
    );
  }

  TenantAdminStaticProfileTypeDefinition _mapStaticProfileType(
    Map<String, dynamic> json,
  ) {
    final dto = TenantAdminStaticProfileTypeDTO.fromJson(json);
    return TenantAdminStaticProfileTypeDefinition(
      type: dto.type,
      label: dto.label,
      allowedTaxonomies: dto.allowedTaxonomies,
      capabilities: TenantAdminStaticProfileTypeCapabilities(
        isPoiEnabled: dto.isPoiEnabled,
        hasBio: dto.hasBio,
        hasTaxonomies: dto.hasTaxonomies,
        hasAvatar: dto.hasAvatar,
        hasCover: dto.hasCover,
        hasContent: dto.hasContent,
      ),
    );
  }

  Map<String, dynamic> _buildStaticProfileTypePayload({
    String? type,
    String? label,
    List<String>? allowedTaxonomies,
    TenantAdminStaticProfileTypeCapabilities? capabilities,
  }) {
    final payload = <String, dynamic>{};
    if (type != null) payload['type'] = type;
    if (label != null) payload['label'] = label;
    if (allowedTaxonomies != null) {
      payload['allowed_taxonomies'] = allowedTaxonomies;
    }
    if (capabilities != null) {
      payload['capabilities'] = {
        'is_poi_enabled': capabilities.isPoiEnabled,
        'has_bio': capabilities.hasBio,
        'has_taxonomies': capabilities.hasTaxonomies,
        'has_avatar': capabilities.hasAvatar,
        'has_cover': capabilities.hasCover,
        'has_content': capabilities.hasContent,
      };
    }
    return payload;
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

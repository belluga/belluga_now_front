import 'package:belluga_now/domain/repositories/landlord_auth_repository_contract.dart';
import 'package:belluga_now/domain/repositories/auth_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_events_repository_contract.dart';
import 'package:belluga_now/domain/services/tenant_admin_tenant_scope_contract.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_event.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_paged_result.dart';
import 'package:belluga_now/infrastructure/dal/dao/tenant_admin/tenant_admin_media_form_data_builder.dart';
import 'package:belluga_now/infrastructure/dal/dao/tenant_admin/tenant_admin_events_request_encoder.dart';
import 'package:belluga_now/infrastructure/dal/dao/tenant_admin/tenant_admin_events_response_decoder.dart';
import 'package:belluga_now/infrastructure/repositories/tenant_admin/tenant_admin_pagination_utils.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

class TenantAdminEventsRepository
    with TenantAdminEventsPaginationMixin
    implements TenantAdminEventsRepositoryContract {
  TenantAdminEventsRepository({
    Dio? dio,
    TenantAdminTenantScopeContract? tenantScope,
  })  : _dio = dio ?? Dio(),
        _tenantScope = tenantScope;

  final Dio _dio;
  final TenantAdminTenantScopeContract? _tenantScope;
  final TenantAdminEventsRequestEncoder _requestEncoder =
      const TenantAdminEventsRequestEncoder();
  final TenantAdminEventsResponseDecoder _responseDecoder =
      const TenantAdminEventsResponseDecoder();
  final TenantAdminMediaFormDataBuilder _mediaFormDataBuilder =
      const TenantAdminMediaFormDataBuilder();

  String get _apiBaseUrl =>
      (_tenantScope ?? GetIt.I.get<TenantAdminTenantScopeContract>())
          .selectedTenantAdminBaseUrl;

  String get _tenantApiBaseUrl =>
      _apiBaseUrl.replaceFirst('/admin/api', '/api');

  Map<String, String> _buildLandlordHeaders() {
    final token = GetIt.I.get<LandlordAuthRepositoryContract>().token.trim();
    if (token.isEmpty) {
      throw const FormatException(
        'Failed to resolve landlord auth token for tenant-admin events request.',
      );
    }
    return {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    };
  }

  Map<String, String> _buildAccountHeaders() {
    final token = GetIt.I.get<AuthRepositoryContract>().userToken.trim();
    if (token.isEmpty) {
      throw const FormatException(
        'Failed to resolve account auth token for account-scoped events request.',
      );
    }
    return {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    };
  }

  Map<String, String> _buildEventTypesReadHeaders() {
    final landlordToken = GetIt.I.isRegistered<LandlordAuthRepositoryContract>()
        ? GetIt.I.get<LandlordAuthRepositoryContract>().token.trim()
        : '';
    if (landlordToken.isNotEmpty) {
      return {
        'Authorization': 'Bearer $landlordToken',
        'Accept': 'application/json',
      };
    }

    final accountToken = GetIt.I.isRegistered<AuthRepositoryContract>()
        ? GetIt.I.get<AuthRepositoryContract>().userToken.trim()
        : '';
    if (accountToken.isNotEmpty) {
      return {
        'Authorization': 'Bearer $accountToken',
        'Accept': 'application/json',
      };
    }

    throw const FormatException(
      'Failed to resolve auth token for event types request.',
    );
  }

  @override
  Future<List<TenantAdminEvent>> fetchEvents({
    String? search,
    String? status,
    bool archived = false,
  }) async {
    var page = 1;
    const pageSize = 100;
    var hasMore = true;
    final events = <TenantAdminEvent>[];

    while (hasMore) {
      final result = await fetchEventsPage(
        page: page,
        pageSize: pageSize,
        search: search,
        status: status,
        archived: archived,
      );
      events.addAll(result.items);
      hasMore = result.hasMore;
      page += 1;
    }

    return List<TenantAdminEvent>.unmodifiable(events);
  }

  @override
  Future<TenantAdminPagedResult<TenantAdminEvent>> fetchEventsPage({
    required int page,
    required int pageSize,
    String? search,
    String? status,
    bool archived = false,
  }) async {
    try {
      final normalizedSearch = search?.trim();
      final response = await _dio.get(
        '$_apiBaseUrl/v1/events',
        queryParameters: {
          'page': page,
          'page_size': pageSize,
          if (normalizedSearch != null && normalizedSearch.isNotEmpty)
            'search': normalizedSearch,
          if (status != null && status.trim().isNotEmpty) 'status': status,
          if (archived) 'archived': 1,
        },
        options: Options(headers: _buildLandlordHeaders()),
      );
      return TenantAdminPagedResult<TenantAdminEvent>(
        items: _responseDecoder.decodeEventList(response.data),
        hasMore: tenantAdminResolveHasMore(
          rawResponse: response.data,
          requestedPage: page,
        ),
      );
    } on DioException catch (error) {
      throw _wrapError(error, 'load events page');
    }
  }

  @override
  Future<TenantAdminEvent> fetchEvent(String eventIdOrSlug) async {
    try {
      final response = await _dio.get(
        '$_apiBaseUrl/v1/events/$eventIdOrSlug',
        options: Options(headers: _buildLandlordHeaders()),
      );
      return _responseDecoder.decodeEventItem(response.data);
    } on DioException catch (error) {
      throw _wrapError(error, 'load event');
    }
  }

  @override
  Future<TenantAdminEvent> createEvent({
    required TenantAdminEventDraft draft,
  }) async {
    try {
      final payload = _requestEncoder.encodeDraft(draft);
      final uploadPayload = _mediaFormDataBuilder.buildAvatarCoverPayload(
        payload: payload,
        coverUpload: draft.coverUpload,
      );
      final hasMultipart = uploadPayload != null || draft.removeCover;
      final requestPayload = hasMultipart
          ? _prepareEventMultipartPayload(
              payload: payload,
              uploadPayload: uploadPayload,
              removeCover: draft.removeCover,
            )
          : payload;
      final response = await _dio.post(
        '$_apiBaseUrl/v1/events',
        data: requestPayload,
        options: Options(
          headers: _buildLandlordHeaders(),
          contentType: hasMultipart ? 'multipart/form-data' : null,
        ),
      );
      return _responseDecoder.decodeEventItem(response.data);
    } on DioException catch (error) {
      throw _wrapError(error, 'create event');
    }
  }

  @override
  Future<TenantAdminEvent> createOwnEvent({
    required String accountSlug,
    required TenantAdminEventDraft draft,
  }) async {
    try {
      final payload = _requestEncoder.encodeDraft(draft);
      final uploadPayload = _mediaFormDataBuilder.buildAvatarCoverPayload(
        payload: payload,
        coverUpload: draft.coverUpload,
      );
      final hasMultipart = uploadPayload != null || draft.removeCover;
      final requestPayload = hasMultipart
          ? _prepareEventMultipartPayload(
              payload: payload,
              uploadPayload: uploadPayload,
              removeCover: draft.removeCover,
            )
          : payload;
      final response = await _dio.post(
        '$_tenantApiBaseUrl/v1/accounts/$accountSlug/events',
        data: requestPayload,
        options: Options(
          headers: _buildAccountHeaders(),
          contentType: hasMultipart ? 'multipart/form-data' : null,
        ),
      );
      return _responseDecoder.decodeEventItem(response.data);
    } on DioException catch (error) {
      throw _wrapError(error, 'create own event');
    }
  }

  @override
  Future<TenantAdminEvent> updateEvent({
    required String eventId,
    required TenantAdminEventDraft draft,
  }) async {
    try {
      final payload = _requestEncoder.encodeDraft(draft);
      final uploadPayload = _mediaFormDataBuilder.buildAvatarCoverPayload(
        payload: payload,
        coverUpload: draft.coverUpload,
      );
      final hasMultipart = uploadPayload != null || draft.removeCover;
      final response = hasMultipart
          ? await _dio.post(
              '$_apiBaseUrl/v1/events/$eventId',
              data: _prepareEventMultipartPayload(
                payload: payload,
                uploadPayload: uploadPayload,
                removeCover: draft.removeCover,
                includePatchMethodOverride: true,
              ),
              options: Options(
                headers: _buildLandlordHeaders(),
                contentType: 'multipart/form-data',
              ),
            )
          : await _dio.patch(
              '$_apiBaseUrl/v1/events/$eventId',
              data: payload,
              options: Options(headers: _buildLandlordHeaders()),
            );
      return _responseDecoder.decodeEventItem(response.data);
    } on DioException catch (error) {
      throw _wrapError(error, 'update event');
    }
  }

  @override
  Future<void> deleteEvent(String eventId) async {
    try {
      await _dio.delete(
        '$_apiBaseUrl/v1/events/$eventId',
        options: Options(headers: _buildLandlordHeaders()),
      );
    } on DioException catch (error) {
      throw _wrapError(error, 'delete event');
    }
  }

  @override
  Future<List<TenantAdminEventType>> fetchEventTypes() async {
    try {
      final response = await _dio.get(
        '$_apiBaseUrl/v1/event_types',
        options: Options(headers: _buildEventTypesReadHeaders()),
      );
      final types = _responseDecoder.decodeEventTypeList(response.data);
      return List<TenantAdminEventType>.unmodifiable(types);
    } on DioException catch (error) {
      throw _wrapError(error, 'load event types');
    }
  }

  @override
  Future<TenantAdminEventType> createEventType({
    required String name,
    required String slug,
    String? description,
  }) async {
    try {
      final normalizedDescription = description?.trim();
      final response = await _dio.post(
        '$_apiBaseUrl/v1/event_types',
        data: {
          'name': name,
          'slug': slug,
          if (normalizedDescription != null && normalizedDescription.isNotEmpty)
            'description': normalizedDescription,
        },
        options: Options(headers: _buildLandlordHeaders()),
      );
      return _responseDecoder.decodeEventTypeItem(response.data);
    } on DioException catch (error) {
      throw _wrapError(error, 'create event type');
    }
  }

  @override
  Future<TenantAdminEventType> updateEventType({
    required String eventTypeId,
    String? name,
    String? slug,
    String? description,
  }) async {
    try {
      final normalizedDescription = description?.trim();
      final payload = _requestEncoder.encodeEventTypePatch(
        name: name,
        slug: slug,
        description: normalizedDescription,
        includeDescription: true,
      );

      final response = await _dio.patch(
        '$_apiBaseUrl/v1/event_types/$eventTypeId',
        data: payload,
        options: Options(headers: _buildLandlordHeaders()),
      );

      return _responseDecoder.decodeEventTypeItem(response.data);
    } on DioException catch (error) {
      throw _wrapError(error, 'update event type');
    }
  }

  @override
  Future<void> deleteEventType(String eventTypeId) async {
    try {
      await _dio.delete(
        '$_apiBaseUrl/v1/event_types/$eventTypeId',
        options: Options(headers: _buildLandlordHeaders()),
      );
    } on DioException catch (error) {
      throw _wrapError(error, 'delete event type');
    }
  }

  @override
  Future<TenantAdminEventPartyCandidates> fetchPartyCandidates({
    String? search,
    String? accountSlug,
  }) async {
    try {
      final normalizedAccountSlug = accountSlug?.trim();
      final isAccountScoped =
          normalizedAccountSlug != null && normalizedAccountSlug.isNotEmpty;

      final response = await _dio.get(
        isAccountScoped
            ? '$_tenantApiBaseUrl/v1/accounts/$normalizedAccountSlug/events/party_candidates'
            : '$_apiBaseUrl/v1/events/party_candidates',
        queryParameters: {
          if (search != null && search.trim().isNotEmpty) 'search': search,
          'limit': 100,
        },
        options: Options(
          headers: isAccountScoped
              ? _buildAccountHeaders()
              : _buildLandlordHeaders(),
          connectTimeout: const Duration(seconds: 20),
          sendTimeout: const Duration(seconds: 20),
          receiveTimeout: const Duration(seconds: 20),
        ),
      );

      return _responseDecoder.decodePartyCandidates(response.data);
    } on DioException catch (error) {
      throw _wrapError(error, 'load event party candidates');
    }
  }

  FormatException _wrapError(DioException error, String context) {
    final status = error.response?.statusCode;
    final uri = error.requestOptions.uri;
    final payload = error.response?.data;
    final fallback = payload?.toString() ?? error.message ?? error.toString();
    final message = _responseDecoder.decodeErrorMessage(
      payload: payload,
      fallback: fallback,
    );
    return FormatException(
      'Failed to $context [status=$status] ($uri): $message',
    );
  }

  FormData _prepareEventMultipartPayload({
    required Object payload,
    required FormData? uploadPayload,
    required bool removeCover,
    bool includePatchMethodOverride = false,
  }) {
    final formData = uploadPayload ??
        _mediaFormDataBuilder.buildMultipartPayload(payload: payload);
    if (removeCover) {
      formData.fields.add(const MapEntry('remove_cover', '1'));
    }
    if (includePatchMethodOverride) {
      formData.fields.add(const MapEntry('_method', 'PATCH'));
    }
    return formData;
  }
}

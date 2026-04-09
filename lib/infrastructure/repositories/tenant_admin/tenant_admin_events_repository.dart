import 'package:belluga_now/domain/repositories/landlord_auth_repository_contract.dart';
import 'package:belluga_now/domain/repositories/auth_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_events_repository_contract.dart';
import 'package:belluga_now/domain/services/tenant_admin_tenant_scope_contract.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_event.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_event_account_profile_candidate_type.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_event_temporal_bucket.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_legacy_event_parties_summary.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_media_upload.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_paged_result.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_poi_visual.dart';
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
    TenantAdminEventsRepoString? search,
    TenantAdminEventsRepoString? status,
    TenantAdminEventsRepoBool? archived,
    Set<TenantAdminEventTemporalBucket>? temporalBuckets,
  }) async {
    var page = 1;
    const pageSize = 100;
    var hasMore = true;
    final events = <TenantAdminEvent>[];

    while (hasMore) {
      final result = await fetchEventsPage(
        page: TenantAdminEventsRepoInt.fromRaw(page, defaultValue: page),
        pageSize:
            TenantAdminEventsRepoInt.fromRaw(pageSize, defaultValue: pageSize),
        search: search,
        status: status,
        archived: archived,
        temporalBuckets: temporalBuckets,
      );
      events.addAll(result.items);
      hasMore = result.hasMore;
      page += 1;
    }

    return List<TenantAdminEvent>.unmodifiable(events);
  }

  @override
  Future<TenantAdminPagedResult<TenantAdminEvent>> fetchEventsPage({
    required TenantAdminEventsRepoInt page,
    required TenantAdminEventsRepoInt pageSize,
    TenantAdminEventsRepoString? search,
    TenantAdminEventsRepoString? status,
    TenantAdminEventsRepoBool? archived,
    Set<TenantAdminEventTemporalBucket>? temporalBuckets,
  }) async {
    try {
      final normalizedSearch = search?.value.trim();
      final normalizedStatus = status?.value.trim();
      final archivedValue = archived?.value ?? false;
      final normalizedTemporal = temporalBuckets == null
          ? const <String>[]
          : temporalBuckets.map((bucket) => bucket.apiValue).toList(
                growable: false,
              );
      final response = await _dio.get(
        '$_apiBaseUrl/v1/events',
        queryParameters: {
          'page': page.value,
          'page_size': pageSize.value,
          if (normalizedSearch != null && normalizedSearch.isNotEmpty)
            'search': normalizedSearch,
          if (normalizedStatus != null && normalizedStatus.isNotEmpty)
            'status': normalizedStatus,
          if (archivedValue) 'archived': 1,
          if (normalizedTemporal.isNotEmpty)
            'temporal': normalizedTemporal.join(','),
        },
        options: Options(headers: _buildLandlordHeaders()),
      );
      return tenantAdminPagedResultFromRaw(
        items: _responseDecoder.decodeEventList(response.data),
        hasMore: tenantAdminResolveHasMore(
          rawResponse: response.data,
          requestedPage: page.value,
        ),
      );
    } on DioException catch (error) {
      throw _wrapError(error, 'load events page');
    } on FormatException catch (error) {
      throw _wrapDecodeError(
        error,
        context: 'load events page',
        uri: '$_apiBaseUrl/v1/events',
      );
    } catch (error) {
      throw _wrapUnknownDecodeError(
        error,
        context: 'load events page',
        uri: '$_apiBaseUrl/v1/events',
      );
    }
  }

  @override
  Future<TenantAdminEvent> fetchEvent(
    TenantAdminEventsRepoString eventIdOrSlug,
  ) async {
    try {
      final response = await _dio.get(
        '$_apiBaseUrl/v1/events/${eventIdOrSlug.value}',
        options: Options(headers: _buildLandlordHeaders()),
      );
      return _responseDecoder.decodeEventItem(response.data);
    } on DioException catch (error) {
      throw _wrapError(error, 'load event');
    } on FormatException catch (error) {
      throw _wrapDecodeError(
        error,
        context: 'load event',
        uri: '$_apiBaseUrl/v1/events/${eventIdOrSlug.value}',
      );
    } catch (error) {
      throw _wrapUnknownDecodeError(
        error,
        context: 'load event',
        uri: '$_apiBaseUrl/v1/events/${eventIdOrSlug.value}',
      );
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
    required TenantAdminEventsRepoString accountSlug,
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
        '$_tenantApiBaseUrl/v1/accounts/${accountSlug.value}/events',
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
    required TenantAdminEventsRepoString eventId,
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
              '$_apiBaseUrl/v1/events/${eventId.value}',
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
              '$_apiBaseUrl/v1/events/${eventId.value}',
              data: payload,
              options: Options(headers: _buildLandlordHeaders()),
            );
      return _responseDecoder.decodeEventItem(response.data);
    } on DioException catch (error) {
      throw _wrapError(error, 'update event');
    }
  }

  @override
  Future<void> deleteEvent(TenantAdminEventsRepoString eventId) async {
    try {
      await _dio.delete(
        '$_apiBaseUrl/v1/events/${eventId.value}',
        options: Options(headers: _buildLandlordHeaders()),
      );
    } on DioException catch (error) {
      throw _wrapError(error, 'delete event');
    }
  }

  @override
  Future<TenantAdminLegacyEventPartiesSummary>
      fetchLegacyEventPartiesSummary() async {
    try {
      final response = await _dio.get(
        '$_apiBaseUrl/v1/events/legacy_event_parties/summary',
        options: Options(headers: _buildLandlordHeaders()),
      );
      return _responseDecoder.decodeLegacyEventPartiesSummary(response.data);
    } on DioException catch (error) {
      throw _wrapError(error, 'load legacy event parties summary');
    }
  }

  @override
  Future<TenantAdminLegacyEventPartiesSummary>
      repairLegacyEventParties() async {
    try {
      final response = await _dio.post(
        '$_apiBaseUrl/v1/events/legacy_event_parties/repair',
        options: Options(headers: _buildLandlordHeaders()),
      );
      return _responseDecoder.decodeLegacyEventPartiesSummary(response.data);
    } on DioException catch (error) {
      throw _wrapError(error, 'repair legacy event parties');
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
    required TenantAdminEventsRepoString name,
    required TenantAdminEventsRepoString slug,
    TenantAdminEventsRepoString? description,
  }) async {
    try {
      final normalizedDescription = description?.value.trim();
      final payload = _requestEncoder.encodeEventTypeCreate(
        name: name.value,
        slug: slug.value,
        description: normalizedDescription,
      );
      final response = await _dio.post(
        '$_apiBaseUrl/v1/event_types',
        data: payload,
        options: Options(headers: _buildLandlordHeaders()),
      );
      return _responseDecoder.decodeEventTypeItem(response.data);
    } on DioException catch (error) {
      throw _wrapError(error, 'create event type');
    }
  }

  @override
  Future<TenantAdminEventType> createEventTypeWithVisual({
    required TenantAdminEventsRepoString name,
    required TenantAdminEventsRepoString slug,
    TenantAdminEventsRepoString? description,
    TenantAdminPoiVisual? visual,
    TenantAdminMediaUpload? typeAssetUpload,
  }) async {
    try {
      final normalizedDescription = description?.value.trim();
      final payload = _requestEncoder.encodeEventTypeCreate(
        name: name.value,
        slug: slug.value,
        description: normalizedDescription,
        visual: visual,
        includeVisual: true,
      );
      final uploadPayload = _mediaFormDataBuilder.buildTypeAssetPayload(
        payload: payload,
        typeAssetUpload: typeAssetUpload,
      );
      final response = await _dio.post(
        '$_apiBaseUrl/v1/event_types',
        data: uploadPayload ?? payload,
        options: uploadPayload == null
            ? Options(headers: _buildLandlordHeaders())
            : Options(
                headers: _buildLandlordHeaders(),
                contentType: 'multipart/form-data',
              ),
      );
      return _responseDecoder.decodeEventTypeItem(response.data);
    } on DioException catch (error) {
      throw _wrapError(error, 'create event type');
    }
  }

  @override
  Future<TenantAdminEventType> updateEventType({
    required TenantAdminEventsRepoString eventTypeId,
    TenantAdminEventsRepoString? name,
    TenantAdminEventsRepoString? slug,
    TenantAdminEventsRepoString? description,
  }) async {
    try {
      final normalizedDescription = description?.value.trim();
      final payload = _requestEncoder.encodeEventTypePatch(
        name: name?.value,
        slug: slug?.value,
        description: normalizedDescription,
        includeDescription: true,
      );

      final response = await _dio.patch(
        '$_apiBaseUrl/v1/event_types/${eventTypeId.value}',
        data: payload,
        options: Options(headers: _buildLandlordHeaders()),
      );

      return _responseDecoder.decodeEventTypeItem(response.data);
    } on DioException catch (error) {
      throw _wrapError(error, 'update event type');
    }
  }

  @override
  Future<TenantAdminEventType> updateEventTypeWithVisual({
    required TenantAdminEventsRepoString eventTypeId,
    TenantAdminEventsRepoString? name,
    TenantAdminEventsRepoString? slug,
    TenantAdminEventsRepoString? description,
    TenantAdminPoiVisual? visual,
    TenantAdminMediaUpload? typeAssetUpload,
    TenantAdminEventsRepoBool? removeTypeAsset,
  }) async {
    try {
      final normalizedDescription = description?.value.trim();
      final payload = _requestEncoder.encodeEventTypePatch(
        name: name?.value,
        slug: slug?.value,
        description: normalizedDescription,
        visual: visual,
        includeDescription: true,
        includeVisual: true,
        removeTypeAsset: removeTypeAsset?.value ?? false,
      );
      final uploadPayload = _mediaFormDataBuilder.buildTypeAssetPayload(
        payload: payload,
        typeAssetUpload: typeAssetUpload,
      );

      final response = uploadPayload == null
          ? await _dio.patch(
              '$_apiBaseUrl/v1/event_types/${eventTypeId.value}',
              data: payload,
              options: Options(headers: _buildLandlordHeaders()),
            )
          : await _dio.post(
              '$_apiBaseUrl/v1/event_types/${eventTypeId.value}',
              data: uploadPayload
                ..fields.add(const MapEntry('_method', 'PATCH')),
              options: Options(
                headers: _buildLandlordHeaders(),
                contentType: 'multipart/form-data',
              ),
            );

      return _responseDecoder.decodeEventTypeItem(response.data);
    } on DioException catch (error) {
      throw _wrapError(error, 'update event type');
    }
  }

  @override
  Future<void> deleteEventType(TenantAdminEventsRepoString eventTypeId) async {
    try {
      await _dio.delete(
        '$_apiBaseUrl/v1/event_types/${eventTypeId.value}',
        options: Options(headers: _buildLandlordHeaders()),
      );
    } on DioException catch (error) {
      throw _wrapError(error, 'delete event type');
    }
  }

  @override
  Future<TenantAdminPagedResult<TenantAdminAccountProfile>>
      fetchEventAccountProfileCandidatesPage({
    required TenantAdminEventAccountProfileCandidateType candidateType,
    required TenantAdminEventsRepoInt page,
    required TenantAdminEventsRepoInt pageSize,
    TenantAdminEventsRepoString? search,
    TenantAdminEventsRepoString? accountSlug,
  }) async {
    try {
      final normalizedAccountSlug = accountSlug?.value.trim();
      final isAccountScoped =
          normalizedAccountSlug != null && normalizedAccountSlug.isNotEmpty;

      final response = await _dio.get(
        isAccountScoped
            ? '$_tenantApiBaseUrl/v1/accounts/$normalizedAccountSlug/events/account_profile_candidates'
            : '$_apiBaseUrl/v1/events/account_profile_candidates',
        queryParameters: {
          'type': candidateType.apiValue,
          'page': page.value,
          'page_size': pageSize.value,
          if (search != null && search.value.trim().isNotEmpty)
            'search': search.value,
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

      return tenantAdminPagedResultFromRaw(
        items: _responseDecoder.decodeAccountProfileCandidates(response.data),
        hasMore: tenantAdminResolveHasMore(
          rawResponse: response.data,
          requestedPage: page.value,
        ),
      );
    } on DioException catch (error) {
      throw _wrapError(error, 'load event account profile candidates');
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

  FormatException _wrapDecodeError(
    FormatException error, {
    required String context,
    required String uri,
  }) {
    return FormatException(
      'Failed to $context [decode] ($uri): ${error.message}',
    );
  }

  FormatException _wrapUnknownDecodeError(
    Object error, {
    required String context,
    required String uri,
  }) {
    return FormatException(
      'Failed to $context [decode] ($uri): $error',
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

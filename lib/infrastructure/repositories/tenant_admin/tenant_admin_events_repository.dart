import 'package:belluga_now/domain/repositories/landlord_auth_repository_contract.dart';
import 'package:belluga_now/domain/repositories/auth_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_events_repository_contract.dart';
import 'package:belluga_now/domain/services/tenant_admin_tenant_scope_contract.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_event.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_location.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_paged_result.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_term.dart';
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
      final ignoredSearch = search?.trim();
      if (ignoredSearch != null && ignoredSearch.isNotEmpty) {
        // MVP contract: events listing does not accept text search.
      }
      final response = await _dio.get(
        '$_apiBaseUrl/v1/events',
        queryParameters: {
          'page': page,
          'page_size': pageSize,
          if (status != null && status.trim().isNotEmpty) 'status': status,
          if (archived) 'archived': 1,
        },
        options: Options(headers: _buildLandlordHeaders()),
      );
      final data = _extractList(response.data);
      return TenantAdminPagedResult<TenantAdminEvent>(
        items: data.map(_mapEvent).toList(growable: false),
        hasMore: tenantAdminResolveHasMore(
          rawResponse: response.data,
          requestedPage: page,
        ),
      );
    } on DioException catch (error) {
      if (_isNotFound(error)) {
        return const TenantAdminPagedResult<TenantAdminEvent>(
          items: <TenantAdminEvent>[],
          hasMore: false,
        );
      }
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
      final item = _extractItem(response.data);
      return _mapEvent(item);
    } on DioException catch (error) {
      throw _wrapError(error, 'load event');
    }
  }

  @override
  Future<TenantAdminEvent> createEvent({
    required TenantAdminEventDraft draft,
  }) async {
    try {
      final response = await _dio.post(
        '$_apiBaseUrl/v1/events',
        data: _buildDraftPayload(draft),
        options: Options(headers: _buildLandlordHeaders()),
      );
      final item = _extractItem(response.data);
      return _mapEvent(item);
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
      final response = await _dio.post(
        '$_tenantApiBaseUrl/v1/accounts/$accountSlug/events',
        data: _buildDraftPayload(draft),
        options: Options(headers: _buildAccountHeaders()),
      );
      final item = _extractItem(response.data);
      return _mapEvent(item);
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
      final response = await _dio.patch(
        '$_apiBaseUrl/v1/events/$eventId',
        data: _buildDraftPayload(draft),
        options: Options(headers: _buildLandlordHeaders()),
      );
      final item = _extractItem(response.data);
      return _mapEvent(item);
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
      final rows = _extractList(response.data);
      final types = rows.map(_mapEventType).toList(growable: false);
      return List<TenantAdminEventType>.unmodifiable(types);
    } on DioException catch (error) {
      throw _wrapError(error, 'load event types');
    }
  }

  @override
  Future<TenantAdminEventType> createEventType({
    required String name,
    required String slug,
    required String description,
  }) async {
    try {
      final response = await _dio.post(
        '$_apiBaseUrl/v1/event_types',
        data: {
          'name': name,
          'slug': slug,
          'description': description,
        },
        options: Options(headers: _buildLandlordHeaders()),
      );
      return _mapEventType(_extractItem(response.data));
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
      final payload = <String, Object?>{};
      if (name != null) {
        payload['name'] = name;
      }
      if (slug != null) {
        payload['slug'] = slug;
      }
      if (description != null) {
        payload['description'] = description;
      }

      final response = await _dio.patch(
        '$_apiBaseUrl/v1/event_types/$eventTypeId',
        data: payload,
        options: Options(headers: _buildLandlordHeaders()),
      );

      return _mapEventType(_extractItem(response.data));
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

      final envelope = _extractItem(response.data);
      final venuesRaw = _asList(envelope['venues']);
      final artistsRaw = _asList(envelope['artists']);

      final venues = venuesRaw
          .whereType<Map>()
          .map((row) => _mapAccountProfile(row.cast<String, Object?>()))
          .toList(growable: false);
      final artists = artistsRaw
          .whereType<Map>()
          .map((row) => _mapAccountProfile(row.cast<String, Object?>()))
          .toList(growable: false);

      return TenantAdminEventPartyCandidates(
        venues: venues,
        artists: artists,
      );
    } on DioException catch (error) {
      throw _wrapError(error, 'load event party candidates');
    }
  }

  TenantAdminEvent _mapEvent(Map<String, Object?> row) {
    final typeRow = _asMap(row['type']);
    final publicationRow = _asMap(row['publication']);
    final locationRow = _asMap(row['location']);
    final placeRefRow = _asMap(row['place_ref']);

    final occurrencesRaw = _asList(row['occurrences']);
    final occurrences = occurrencesRaw
        .map((raw) => _asMap(raw))
        .where((item) => item.isNotEmpty)
        .map((item) {
          final start = _parseDate(item['date_time_start']);
          if (start == null) {
            return null;
          }
          return TenantAdminEventOccurrence(
            occurrenceId: _asString(item['occurrence_id']),
            occurrenceSlug: _asString(item['occurrence_slug']),
            dateTimeStart: start,
            dateTimeEnd: _parseDate(item['date_time_end']),
          );
        })
        .whereType<TenantAdminEventOccurrence>()
        .toList(growable: false);

    final artistIdsRaw = _asList(row['artist_ids']);
    final artistIds = artistIdsRaw
        .map(_asString)
        .where((value) => value != null && value.isNotEmpty)
        .cast<String>()
        .toList(growable: false);

    final taxonomyTermsRaw = _asList(row['taxonomy_terms']);
    final taxonomyTerms = taxonomyTermsRaw
        .map((term) => _asMap(term))
        .where((term) => term.isNotEmpty)
        .map((term) {
          final type = _asString(term['type']) ?? '';
          final value = _asString(term['value']) ?? '';
          return TenantAdminTaxonomyTerm(type: type, value: value);
        })
        .where((term) => term.type.isNotEmpty && term.value.isNotEmpty)
        .toList(
          growable: false,
        );

    final eventPartiesRaw = _asList(row['event_parties']);
    final eventParties = eventPartiesRaw
        .map((party) => _asMap(party))
        .where((party) => party.isNotEmpty)
        .map((party) {
          final permissions = _asMap(party['permissions']);
          final canEdit = permissions['can_edit'] == true;
          return TenantAdminEventParty(
            partyType: _asString(party['party_type']) ?? '',
            partyRefId: _asString(party['party_ref_id']) ?? '',
            canEdit: canEdit,
            metadata: _asMap(party['metadata']),
          );
        })
        .where((party) =>
            party.partyType.isNotEmpty && party.partyRefId.isNotEmpty)
        .toList(
          growable: false,
        );

    final onlineRow = _asMap(locationRow['online']);
    final mode = _asString(locationRow['mode']) ?? '';
    final latitude = _toDouble(row['latitude']);
    final longitude = _toDouble(row['longitude']);

    final location = mode.isEmpty
        ? null
        : TenantAdminEventLocation(
            mode: mode,
            latitude: latitude,
            longitude: longitude,
            online: onlineRow.isEmpty
                ? null
                : TenantAdminEventOnlineLocation(
                    url: _asString(onlineRow['url']) ?? '',
                    platform: _asString(onlineRow['platform']),
                    label: _asString(onlineRow['label']),
                  ),
          );

    final placeRef = placeRefRow.isEmpty
        ? null
        : TenantAdminEventPlaceRef(
            type: _asString(placeRefRow['type']) ?? '',
            id: _asString(placeRefRow['id']) ?? '',
            metadata: _asMap(placeRefRow['metadata']),
          );

    final dateTimeStart = _parseDate(row['date_time_start']);
    if (occurrences.isEmpty && dateTimeStart != null) {
      final fallbackOccurrence = TenantAdminEventOccurrence(
        dateTimeStart: dateTimeStart,
        dateTimeEnd: _parseDate(row['date_time_end']),
      );
      return TenantAdminEvent(
        eventId: _asString(row['event_id']) ?? _asString(row['id']) ?? '',
        slug: _asString(row['slug']) ?? '',
        title: _asString(row['title']) ?? '',
        content: _asString(row['content']) ?? '',
        type: TenantAdminEventType(
          id: _asString(typeRow['id']),
          name: _asString(typeRow['name']) ?? '',
          slug: _asString(typeRow['slug']) ?? '',
          description: _asString(typeRow['description']),
          icon: _asString(typeRow['icon']),
          color: _asString(typeRow['color']),
        ),
        location: location,
        placeRef: placeRef,
        occurrences: <TenantAdminEventOccurrence>[fallbackOccurrence],
        publication: TenantAdminEventPublication(
          status: _asString(publicationRow['status']) ?? 'draft',
          publishAt: _parseDate(publicationRow['publish_at']),
        ),
        artistIds: artistIds,
        eventParties: eventParties,
        taxonomyTerms: taxonomyTerms,
        createdAt: _parseDate(row['created_at']),
        updatedAt: _parseDate(row['updated_at']),
        deletedAt: _parseDate(row['deleted_at']),
      );
    }

    return TenantAdminEvent(
      eventId: _asString(row['event_id']) ?? _asString(row['id']) ?? '',
      slug: _asString(row['slug']) ?? '',
      title: _asString(row['title']) ?? '',
      content: _asString(row['content']) ?? '',
      type: TenantAdminEventType(
        id: _asString(typeRow['id']),
        name: _asString(typeRow['name']) ?? '',
        slug: _asString(typeRow['slug']) ?? '',
        description: _asString(typeRow['description']),
        icon: _asString(typeRow['icon']),
        color: _asString(typeRow['color']),
      ),
      location: location,
      placeRef: placeRef,
      occurrences: occurrences,
      publication: TenantAdminEventPublication(
        status: _asString(publicationRow['status']) ?? 'draft',
        publishAt: _parseDate(publicationRow['publish_at']),
      ),
      artistIds: artistIds,
      eventParties: eventParties,
      taxonomyTerms: taxonomyTerms,
      createdAt: _parseDate(row['created_at']),
      updatedAt: _parseDate(row['updated_at']),
      deletedAt: _parseDate(row['deleted_at']),
    );
  }

  TenantAdminEventType _mapEventType(Map<String, Object?> row) {
    return TenantAdminEventType(
      id: _asString(row['id']),
      name: _asString(row['name']) ?? '',
      slug: _asString(row['slug']) ?? '',
      description: _asString(row['description']),
      icon: _asString(row['icon']),
      color: _asString(row['color']),
    );
  }

  TenantAdminAccountProfile _mapAccountProfile(Map<String, Object?> row) {
    final locationRow = _asMap(row['location']);
    final lat = _toDouble(locationRow['lat']);
    final lng = _toDouble(locationRow['lng']);

    final taxonomyTerms = _asList(row['taxonomy_terms'])
        .map((term) => _asMap(term))
        .where((term) => term.isNotEmpty)
        .map((term) => TenantAdminTaxonomyTerm(
              type: _asString(term['type']) ?? '',
              value: _asString(term['value']) ?? '',
            ))
        .where((term) => term.type.isNotEmpty && term.value.isNotEmpty)
        .toList(growable: false);

    return TenantAdminAccountProfile(
      id: _asString(row['id']) ?? '',
      accountId: _asString(row['account_id']) ?? '',
      profileType: _asString(row['profile_type']) ?? '',
      displayName: _asString(row['display_name']) ?? '',
      slug: _asString(row['slug']),
      avatarUrl: _asString(row['avatar_url']),
      coverUrl: _asString(row['cover_url']),
      bio: _asString(row['bio']),
      content: _asString(row['content']),
      location: lat != null && lng != null
          ? TenantAdminLocation(latitude: lat, longitude: lng)
          : null,
      taxonomyTerms: taxonomyTerms,
    );
  }

  Map<String, Object?> _buildDraftPayload(TenantAdminEventDraft draft) {
    final payload = <String, Object?>{
      'title': draft.title,
      'content': draft.content,
      'type': {
        'name': draft.type.name,
        'slug': draft.type.slug,
        if (draft.type.id != null && draft.type.id!.trim().isNotEmpty)
          'id': draft.type.id,
        if (draft.type.description != null)
          'description': draft.type.description,
        if (draft.type.icon != null) 'icon': draft.type.icon,
        if (draft.type.color != null) 'color': draft.type.color,
      },
      'occurrences': draft.occurrences
          .map((occurrence) => {
                'date_time_start':
                    occurrence.dateTimeStart.toUtc().toIso8601String(),
                if (occurrence.dateTimeEnd != null)
                  'date_time_end':
                      occurrence.dateTimeEnd!.toUtc().toIso8601String(),
              })
          .toList(growable: false),
      'publication': {
        'status': draft.publication.status,
        if (draft.publication.publishAt != null)
          'publish_at': draft.publication.publishAt!.toUtc().toIso8601String(),
      },
    };

    if (draft.taxonomyTerms.isNotEmpty) {
      payload['taxonomy_terms'] = draft.taxonomyTerms
          .map((term) => {
                'type': term.type,
                'value': term.value,
              })
          .toList(growable: false);
    }

    if (draft.artistIds.isNotEmpty) {
      payload['artist_ids'] = draft.artistIds;
    }

    final location = draft.location;
    if (location != null) {
      final locationPayload = <String, Object?>{
        'mode': location.mode,
      };
      final includesPhysicalGeometry =
          location.mode == 'physical' || location.mode == 'hybrid';
      if (includesPhysicalGeometry &&
          location.latitude != null &&
          location.longitude != null) {
        locationPayload['geo'] = {
          'type': 'Point',
          'coordinates': [location.longitude, location.latitude],
        };
      }
      if (location.online != null) {
        locationPayload['online'] = {
          'url': location.online!.url,
          if (location.online!.platform != null)
            'platform': location.online!.platform,
          if (location.online!.label != null) 'label': location.online!.label,
        };
      }
      payload['location'] = locationPayload;
    }

    if (draft.placeRef != null) {
      payload['place_ref'] = {
        'type': draft.placeRef!.type,
        'id': draft.placeRef!.id,
        if (draft.placeRef!.metadata != null &&
            draft.placeRef!.metadata!.isNotEmpty)
          'metadata': draft.placeRef!.metadata,
      };
    } else if (location != null && location.mode == 'online') {
      payload['place_ref'] = null;
    }

    return payload;
  }

  List<Map<String, Object?>> _extractList(Object? raw) {
    if (raw is Map<String, Object?>) {
      final data = raw['data'];
      if (data is List) {
        return data
            .whereType<Map>()
            .map((item) => item.cast<String, Object?>())
            .toList(growable: false);
      }
    }
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((item) => item.cast<String, Object?>())
          .toList(growable: false);
    }
    return const <Map<String, Object?>>[];
  }

  Map<String, Object?> _extractItem(Object? raw) {
    if (raw is Map<String, Object?>) {
      final data = raw['data'];
      if (data is Map) {
        return data.cast<String, Object?>();
      }
      return raw;
    }
    return const <String, Object?>{};
  }

  FormatException _wrapError(DioException error, String context) {
    final status = error.response?.statusCode;
    final uri = error.requestOptions.uri;
    final payload = error.response?.data;
    final message = payload is Map<String, Object?>
        ? (payload['message'] as String?) ?? payload.toString()
        : (payload?.toString() ?? error.message ?? error.toString());
    return FormatException(
      'Failed to $context [status=$status] ($uri): $message',
    );
  }

  bool _isNotFound(DioException error) {
    return error.response?.statusCode == 404;
  }

  Map<String, Object?> _asMap(Object? value) {
    if (value is Map<String, Object?>) {
      return value;
    }
    if (value is Map) {
      return value.cast<String, Object?>();
    }
    return const <String, Object?>{};
  }

  List<Object?> _asList(Object? value) {
    if (value is List) {
      return value;
    }
    return const <Object?>[];
  }

  String? _asString(Object? value) {
    if (value == null) {
      return null;
    }
    final normalized = value.toString();
    if (normalized.trim().isEmpty) {
      return null;
    }
    return normalized;
  }

  double? _toDouble(Object? value) {
    if (value is double) {
      return value;
    }
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }

  DateTime? _parseDate(Object? value) {
    if (value is DateTime) {
      return value;
    }
    if (value is String && value.trim().isNotEmpty) {
      return DateTime.tryParse(value)?.toLocal();
    }
    return null;
  }
}

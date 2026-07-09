import 'dart:convert';

import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/infrastructure/dal/dao/invites/invites_backend_requests.dart';
import 'package:belluga_now/infrastructure/dal/dao/invites/invites_response_decoder.dart';
import 'package:belluga_now/infrastructure/dal/dao/laravel_backend/shared/tenant_public_auth_headers.dart';
import 'package:belluga_now/infrastructure/dal/dto/invites/invite_realtime_delta_dto.dart';
import 'package:belluga_now/infrastructure/services/invites_backend_contract.dart';
import 'package:belluga_now/infrastructure/services/sse/sse_client.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

class LaravelInvitesBackend implements InvitesBackendContract {
  LaravelInvitesBackend({Dio? dio, SseClient? sseClient})
    : _dio = dio ?? Dio(),
      _sseClient = sseClient ?? createSseClient();

  final Dio _dio;
  final SseClient _sseClient;
  final InvitesResponseDecoder _responseDecoder =
      const InvitesResponseDecoder();

  String get _apiBaseUrl =>
      '${GetIt.I.get<AppData>().mainDomainValue.value.origin}/api';

  Future<Map<String, String>> _streamHeaders({bool includeJsonAccept = false}) {
    return TenantPublicAuthHeaders.build(
      includeJsonAccept: includeJsonAccept,
      bootstrapIfEmpty: true,
    );
  }

  @override
  Future<Map<String, dynamic>> fetchInvites({
    required int page,
    required int pageSize,
  }) async {
    return _get(
      '$_apiBaseUrl/v1/invites',
      queryParameters: {'page': page, 'page_size': pageSize},
    );
  }

  @override
  Stream<InviteRealtimeDeltaDto> watchInvitesStream({String? lastEventId}) {
    return Stream<Map<String, String>>.fromFuture(_streamHeaders()).asyncExpand(
      (headers) async* {
        final uri = _inviteStreamUri(
          accessToken: _extractBearerToken(headers),
          lastEventId: lastEventId,
        );
        yield* _sseClient
            .connect(uri, lastEventId: lastEventId, headers: headers)
            .map(
              (message) => _parseRealtimeDelta(
                data: message.data,
                fallbackType: message.event,
                lastEventId: message.id,
              ),
            );
      },
    );
  }

  Uri _inviteStreamUri({required String accessToken, String? lastEventId}) {
    final uri = Uri.parse('$_apiBaseUrl/v1/invites/stream');
    final cursor = lastEventId?.trim() ?? '';
    if (accessToken.isEmpty && cursor.isEmpty) {
      return uri;
    }

    return uri.replace(
      queryParameters: <String, String>{
        ...uri.queryParameters,
        if (accessToken.isNotEmpty) 'access_token': accessToken,
        if (cursor.isNotEmpty) 'last_event_id': cursor,
      },
    );
  }

  String _extractBearerToken(Map<String, String> headers) {
    final raw = headers['Authorization']?.trim() ?? '';
    const prefix = 'Bearer ';
    if (!raw.startsWith(prefix)) {
      return '';
    }
    return raw.substring(prefix.length).trim();
  }

  @override
  Future<Map<String, dynamic>> fetchSettings() {
    return _get('$_apiBaseUrl/v1/invites/settings');
  }

  @override
  Future<Map<String, dynamic>> acceptInvite(String inviteId) {
    return _post('$_apiBaseUrl/v1/invites/$inviteId/accept');
  }

  @override
  Future<Map<String, dynamic>> declineInvite(String inviteId) {
    return _post('$_apiBaseUrl/v1/invites/$inviteId/decline');
  }

  @override
  Future<Map<String, dynamic>> sendInvites(InviteSendRequest request) {
    return _post('$_apiBaseUrl/v1/invites', data: request.toJson());
  }

  @override
  Future<Map<String, dynamic>> fetchSentInviteStatuses(
    InviteSentStatusesRequest request,
  ) {
    return _get(
      '$_apiBaseUrl/v1/invites/sent-statuses',
      queryParameters: request.toQueryParameters(),
    );
  }

  @override
  Future<Map<String, dynamic>> fetchSentInviteSummary(
    InviteSentSummaryRequest request,
  ) {
    return _get(
      '$_apiBaseUrl/v1/invites/sent-summary',
      queryParameters: request.toQueryParameters(),
    );
  }

  @override
  Future<Map<String, dynamic>> createShareCode(
    InviteShareCodeCreateRequest request,
  ) {
    return _post('$_apiBaseUrl/v1/invites/share', data: request.toJson());
  }

  @override
  Future<Map<String, dynamic>> fetchShareCodePreview(String code) {
    return _get('$_apiBaseUrl/v1/invites/share/$code');
  }

  @override
  Future<Map<String, dynamic>> acceptShareCode(String code) {
    return _post('$_apiBaseUrl/v1/invites/share/$code/accept');
  }

  @override
  Future<Map<String, dynamic>> materializeShareCode(String code) {
    return _post('$_apiBaseUrl/v1/invites/share/$code/materialize');
  }

  @override
  Future<Map<String, dynamic>> importContacts(
    InviteContactImportRequest request,
  ) {
    return _post('$_apiBaseUrl/v1/contacts/import', data: request.toJson());
  }

  @override
  Future<Map<String, dynamic>> fetchInviteableContacts(
    InviteableContactsRequest request,
  ) {
    return _get(
      '$_apiBaseUrl/v1/contacts/inviteables',
      queryParameters: request.toQueryParameters(),
    );
  }

  @override
  Future<Map<String, dynamic>> fetchContactGroups() {
    return _get('$_apiBaseUrl/v1/contact-groups');
  }

  @override
  Future<Map<String, dynamic>> createContactGroup({
    required String name,
    required List<String> recipientAccountProfileIds,
  }) {
    return _post(
      '$_apiBaseUrl/v1/contact-groups',
      data: {
        'name': name,
        'recipient_account_profile_ids': recipientAccountProfileIds,
      },
    );
  }

  @override
  Future<Map<String, dynamic>> updateContactGroup({
    required String groupId,
    String? name,
    List<String>? recipientAccountProfileIds,
  }) {
    return _patch(
      '$_apiBaseUrl/v1/contact-groups/$groupId',
      data: {
        'name': ?name,
        'recipient_account_profile_ids': ?recipientAccountProfileIds,
      },
    );
  }

  @override
  Future<Map<String, dynamic>> deleteContactGroup(String groupId) {
    return _delete('$_apiBaseUrl/v1/contact-groups/$groupId');
  }

  Future<Map<String, dynamic>> _get(
    String url, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await TenantPublicAuthHeaders.retryOnceOnUnauthorized(
        includeJsonAccept: true,
        action: (headers) async {
          final response = await _dio.get(
            url,
            queryParameters: queryParameters,
            options: Options(headers: headers),
          );
          return _normalizeResponse(response.data);
        },
      );
    } on DioException catch (error) {
      throw _wrapException('GET', error);
    }
  }

  Future<Map<String, dynamic>> _post(
    String url, {
    Map<String, dynamic>? data,
  }) async {
    try {
      return await TenantPublicAuthHeaders.retryOnceOnUnauthorized(
        includeJsonAccept: true,
        action: (headers) async {
          final response = await _dio.post(
            url,
            data: data,
            options: Options(headers: headers),
          );
          return _normalizeResponse(response.data);
        },
      );
    } on DioException catch (error) {
      throw _wrapException('POST', error);
    }
  }

  Future<Map<String, dynamic>> _patch(
    String url, {
    Map<String, dynamic>? data,
  }) async {
    try {
      return await TenantPublicAuthHeaders.retryOnceOnUnauthorized(
        includeJsonAccept: true,
        action: (headers) async {
          final response = await _dio.patch(
            url,
            data: data,
            options: Options(headers: headers),
          );
          return _normalizeResponse(response.data);
        },
      );
    } on DioException catch (error) {
      throw _wrapException('PATCH', error);
    }
  }

  Future<Map<String, dynamic>> _delete(String url) async {
    try {
      return await TenantPublicAuthHeaders.retryOnceOnUnauthorized(
        includeJsonAccept: true,
        action: (headers) async {
          final response = await _dio.delete(
            url,
            options: Options(headers: headers),
          );
          return _normalizeResponse(response.data);
        },
      );
    } on DioException catch (error) {
      throw _wrapException('DELETE', error);
    }
  }

  Map<String, dynamic> _normalizeResponse(dynamic raw) {
    if (raw == null) {
      return const <String, dynamic>{};
    }
    if (raw is Map<String, dynamic>) {
      final data = raw['data'];
      if (data is Map<String, dynamic>) {
        return data;
      }
      return raw;
    }
    throw Exception('Unexpected invites response shape.');
  }

  Exception _wrapException(String method, DioException error) {
    final statusCode = error.response?.statusCode;
    final data = error.response?.data;
    return Exception(
      'Failed to $method invites request '
      '[status=$statusCode] '
      '(${error.requestOptions.uri}): '
      '${data ?? error.message}',
    );
  }

  InviteRealtimeDeltaDto _parseRealtimeDelta({
    required String data,
    String? fallbackType,
    String? lastEventId,
  }) {
    final decoded = jsonDecode(data);
    if (decoded is! Map) {
      throw const FormatException(
        'Malformed invite realtime payload: expected object.',
      );
    }

    final payload = Map<String, dynamic>.from(decoded);
    final resolvedType =
        _stringOrNull(payload['type']) ??
        fallbackType?.trim() ??
        'invite.updated';

    final invitePayload = payload['invite'];
    final inviteDto = invitePayload == null
        ? null
        : _responseDecoder.decodeRequiredInviteDto(
            invitePayload,
            context: 'invite realtime delta',
          );

    final targetRef = payload['target_ref'];
    final targetRefMap = targetRef is Map
        ? Map<String, dynamic>.from(targetRef)
        : null;

    return InviteRealtimeDeltaDto(
      type: resolvedType,
      invite: inviteDto,
      eventId: _stringOrNull(targetRefMap?['event_id']),
      occurrenceId: _stringOrNull(targetRefMap?['occurrence_id']),
      lastEventId: lastEventId,
    );
  }

  String? _stringOrNull(Object? raw) {
    final value = raw?.toString().trim();
    if (value == null || value.isEmpty) {
      return null;
    }
    return value;
  }
}

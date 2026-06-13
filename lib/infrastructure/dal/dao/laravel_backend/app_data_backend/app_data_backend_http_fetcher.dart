import 'dart:convert';

import 'package:belluga_now/infrastructure/dal/dao/laravel_backend/app_data_backend/environment_origin_normalizer.dart';
import 'package:belluga_now/infrastructure/dal/dto/app_data_dto.dart';
import 'package:dio/dio.dart';

Future<AppDataDTO> fetchAppDataEnvironment({
  required String bootstrapBaseUrl,
  Dio? dio,
  String? appDomain,
  Duration connectTimeout = const Duration(seconds: 5),
  Duration receiveTimeout = const Duration(seconds: 10),
}) async {
  final client = dio ??
      Dio(
        BaseOptions(
          baseUrl: bootstrapBaseUrl,
          connectTimeout: connectTimeout,
          receiveTimeout: receiveTimeout,
        ),
      );
  final resolvedBaseUrl = client.options.baseUrl.trim().isNotEmpty
      ? client.options.baseUrl.trim()
      : bootstrapBaseUrl;
  final normalizedAppDomain = appDomain?.trim() ?? '';
  const url = '/api/v1/environment';

  try {
    final response = await _fetchEnvironmentResponse(
      client: client,
      url: url,
      appDomain: normalizedAppDomain,
    );
    final raw = response.data;
    final Map<String, dynamic> payload;
    if (raw is Map<String, dynamic>) {
      payload = (raw['data'] is Map<String, dynamic>)
          ? raw['data'] as Map<String, dynamic>
          : raw;
    } else if (raw is String && raw.trim().isNotEmpty) {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        payload = (decoded['data'] is Map<String, dynamic>)
            ? decoded['data'] as Map<String, dynamic>
            : decoded;
      } else {
        throw Exception(
          'Unexpected environment response shape for '
          '${response.requestOptions.baseUrl}$url',
        );
      }
    } else {
      throw Exception(
        'Unexpected environment response shape for '
        '${response.requestOptions.baseUrl}$url',
      );
    }

    final normalizedPayload = normalizeEnvironmentOrigins(
      payload,
      bootstrapBaseUrl: resolvedBaseUrl,
    );
    return AppDataDTO.fromJson(normalizedPayload);
  } on DioException catch (error) {
    final statusCode = error.response?.statusCode;
    final data = error.response?.data;
    throw Exception(
      'Failed to load environment data '
      '[${responseLabel(statusCode)}] '
      '(${error.requestOptions.uri}): '
      '${data ?? error.message}',
    );
  } catch (error) {
    throw Exception(
      'Could not retrieve branding data for '
      '$resolvedBaseUrl$url: $error',
    );
  }
}

Future<Response<dynamic>> _fetchEnvironmentResponse({
  required Dio client,
  required String url,
  required String appDomain,
}) async {
  final withAppDomain = <String, String>{
    'Accept': 'application/json',
    if (appDomain.isNotEmpty) 'X-App-Domain': appDomain,
  };

  Response<dynamic> firstResponse;
  try {
    firstResponse = await client.get(
      url,
      options: Options(headers: withAppDomain),
    );
  } on DioException catch (error) {
    if (!withAppDomain.containsKey('X-App-Domain') ||
        !_isUnknownAppDomain(error)) {
      rethrow;
    }

    return client.get(
      url,
      options: Options(
        headers: const <String, String>{
          'Accept': 'application/json',
        },
      ),
    );
  }

  if (!withAppDomain.containsKey('X-App-Domain') ||
      !_looksLikeHtmlResponse(firstResponse.data)) {
    return firstResponse;
  }

  return client.get(
    url,
    options: Options(
      headers: const <String, String>{
        'Accept': 'application/json',
      },
    ),
  );
}

bool _looksLikeHtmlResponse(dynamic raw) {
  if (raw is! String) {
    return false;
  }

  final normalized = raw.trimLeft().toLowerCase();
  return normalized.startsWith('<!doctype html') ||
      normalized.startsWith('<html');
}

bool _isUnknownAppDomain(DioException error) {
  final payload = error.response?.data;
  if (payload is Map<String, dynamic>) {
    final message = payload['message']?.toString().toLowerCase() ?? '';
    if (message.contains('unknown app_domain')) {
      return true;
    }

    final errors = payload['errors'];
    if (errors is Map<String, dynamic>) {
      final appDomainErrors = errors['app_domain'];
      if (appDomainErrors is List &&
          appDomainErrors.any(
            (entry) =>
                entry.toString().toLowerCase().contains('unknown app_domain'),
          )) {
        return true;
      }
    }
    return false;
  }

  final raw = payload?.toString().toLowerCase() ?? '';
  return raw.contains('unknown app_domain');
}

String responseLabel(int? statusCode) {
  if (statusCode == null) return 'status=unknown';
  return 'status=$statusCode';
}

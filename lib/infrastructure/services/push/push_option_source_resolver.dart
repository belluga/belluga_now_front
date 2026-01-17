import 'dart:convert';

import 'package:belluga_now/infrastructure/dal/dao/backend_context.dart';
import 'package:belluga_now/domain/repositories/auth_repository_contract.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:push_handler/push_handler.dart';

class PushOptionSourceResolver {
  PushOptionSourceResolver({
    BackendContext? context,
    Dio? dio,
    AuthRepositoryContract? authRepository,
  })  : _context = context,
        _dio = dio ?? Dio(BaseOptions(baseUrl: _resolveBaseUrl(context))),
        _authRepository = authRepository ?? GetIt.I.get<AuthRepositoryContract>();

  final BackendContext? _context;
  final Dio _dio;
  final AuthRepositoryContract _authRepository;
  final Map<String, _CachedOptions> _cache = {};

  static String _resolveBaseUrl(BackendContext? context) {
    final resolved = context ??
        (GetIt.I.isRegistered<BackendContext>()
            ? GetIt.I.get<BackendContext>()
            : null);
    if (resolved == null) {
      throw StateError(
        'BackendContext is not registered for PushOptionSourceResolver.',
      );
    }
    return resolved.baseUrl;
  }

  Future<List<OptionItem>> resolve(OptionSource source) async {
    if (source.type == 'static') {
      return const [];
    }

    final normalizedParams = _normalizeParams(source);
    final cacheKey = _buildCacheKey(source);
    final cached = _cache[cacheKey];
    if (cached != null && !cached.isExpired) {
      return cached.items;
    }

    final uri = _resolveUri(normalizedParams);
    if (uri == null) {
      return const [];
    }

    try {
      final response = await _dio.get(
        uri.toString(),
        queryParameters: _resolveQuery(normalizedParams),
        options: Options(headers: _buildHeaders()),
      );
      final items = _extractOptions(response.data, normalizedParams);
      _cache[cacheKey] = _CachedOptions(
        items: items,
        expiresAt: _buildExpiry(source.cacheTtlSec),
      );
      return items;
    } catch (_) {
      return const [];
    }
  }

  Map<String, dynamic> _normalizeParams(OptionSource source) {
    final params = Map<String, dynamic>.from(source.params);
    if (params['path'] == null && params['endpoint'] == null && params['url'] == null) {
      if (source.type == 'tags') {
        params['path'] = '/v1/tags';
      } else if (source.type == 'query') {
        params['path'] = '/v1/query';
      }
    }
    return params;
  }

  Uri? _resolveUri(Map<String, dynamic> params) {
    final rawUrl = params['url']?.toString();
    if (rawUrl != null && rawUrl.isNotEmpty) {
      return Uri.tryParse(rawUrl);
    }
    final path = params['path']?.toString() ?? params['endpoint']?.toString();
    if (path == null || path.isEmpty) {
      return null;
    }
    final baseUri = Uri.parse(_resolveBaseUrl(_context));
    return baseUri.resolve(path);
  }

  Map<String, dynamic>? _resolveQuery(Map<String, dynamic> params) {
    final query = params['query'];
    if (query is Map<String, dynamic>) {
      return query;
    }
    return null;
  }

  Map<String, String> _buildHeaders() {
    final token = _authRepository.userToken;
    if (token.isEmpty) {
      return const {};
    }
    return {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    };
  }

  List<OptionItem> _extractOptions(dynamic data, Map<String, dynamic> params) {
    final responsePath = params['response_path']?.toString() ??
        params['items_path']?.toString();
    dynamic resolved = data;
    if (responsePath != null && responsePath.isNotEmpty) {
      resolved = _resolvePath(data, responsePath);
    }

    if (resolved is Map<String, dynamic>) {
      resolved = resolved['data'] ?? resolved['items'] ?? resolved['options'];
    }

    if (resolved is! List) {
      return const [];
    }

    return resolved.map((item) {
      if (item is Map<String, dynamic>) {
        return _optionFromMap(item, params);
      }
      return OptionItem(value: item, label: item?.toString());
    }).toList();
  }

  OptionItem _optionFromMap(Map<String, dynamic> map, Map<String, dynamic> params) {
    final valueField = params['value_field']?.toString();
    final labelField = params['label_field']?.toString();
    final subtitleField = params['subtitle_field']?.toString();
    final imageField = params['image_field']?.toString();

    return OptionItem(
      value: valueField != null ? map[valueField] : map['id'] ?? map['value'] ?? map['key'] ?? map['label'],
      label: labelField != null ? map[labelField]?.toString() : map['label']?.toString(),
      subtitle: subtitleField != null ? map[subtitleField]?.toString() : map['subtitle']?.toString(),
      image: imageField != null ? map[imageField]?.toString() : map['image']?.toString(),
    );
  }

  dynamic _resolvePath(dynamic data, String path) {
    var current = data;
    final parts = path.split('.');
    for (final part in parts) {
      if (current is Map<String, dynamic> && current.containsKey(part)) {
        current = current[part];
      } else {
        return null;
      }
    }
    return current;
  }

  String _buildCacheKey(OptionSource source) {
    final payload = jsonEncode({
      'type': source.type,
      'params': source.params,
    });
    return payload;
  }

  DateTime? _buildExpiry(int? ttlSeconds) {
    if (ttlSeconds == null || ttlSeconds <= 0) {
      return null;
    }
    return DateTime.now().add(Duration(seconds: ttlSeconds));
  }
}

class _CachedOptions {
  const _CachedOptions({
    required this.items,
    required this.expiresAt,
  });

  final List<OptionItem> items;
  final DateTime? expiresAt;

  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);
}

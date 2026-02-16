import 'package:belluga_now/application/configurations/belluga_constants.dart';
import 'package:belluga_now/infrastructure/dal/dao/app_data_backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/laravel_backend/app_data_backend/environment_origin_normalizer.dart';
import 'package:belluga_now/infrastructure/dal/dto/app_data_dto.dart';
import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AppDataBackend implements AppDataBackendContract {
  AppDataBackend({Dio? dio}) : _dio = dio;

  final Dio? _dio;

  @override
  Future<AppDataDTO> fetch() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final url =
        '/api/v1/environment?app_domain=${Uri.encodeComponent(packageInfo.packageName)}';

    final bootstrapBaseUrl = _resolveBootstrapBaseUrl();
    final client = _dio ??
        Dio(
          BaseOptions(
            baseUrl: bootstrapBaseUrl,
            connectTimeout: const Duration(seconds: 5),
            receiveTimeout: const Duration(seconds: 10),
          ),
        );

    try {
      final response = await client.get(url);
      final raw = response.data;
      final Map<String, dynamic> payload;
      if (raw is Map<String, dynamic>) {
        payload = (raw['data'] is Map<String, dynamic>)
            ? raw['data'] as Map<String, dynamic>
            : raw;
      } else {
        throw Exception(
          'Unexpected environment response shape for '
          '${response.requestOptions.baseUrl}$url',
        );
      }

      final normalizedPayload = normalizeEnvironmentOrigins(
        payload,
        bootstrapBaseUrl: bootstrapBaseUrl,
      );
      return AppDataDTO.fromJson(normalizedPayload);
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      final data = e.response?.data;
      throw Exception(
        'Failed to load environment data '
        '[${responseLabel(statusCode)}] '
        '(${e.requestOptions.uri}): '
        '${data ?? e.message}',
      );
    } catch (e) {
      throw Exception(
        'Could not retrieve branding data for '
        '${client.options.baseUrl}$url: $e',
      );
    }
  }

  String _resolveBootstrapBaseUrl() {
    final explicit = BellugaConstants.bootstrapBaseUrlOverride.trim();
    if (explicit.isNotEmpty) {
      return _parseRequiredOrigin(
        explicit,
        fieldName: 'BOOTSTRAP_BASE_URL',
      );
    }

    final landlordDomain = BellugaConstants.landlordDomain.trim();
    if (landlordDomain.isEmpty) {
      throw StateError(
        'Missing landlord bootstrap configuration. '
        'Provide BOOTSTRAP_BASE_URL or LANDLORD_DOMAIN via --dart-define '
        'or --dart-define-from-file (config/defines/<lane>.json).',
      );
    }

    return _parseRequiredOrigin(
      landlordDomain,
      fieldName: 'LANDLORD_DOMAIN',
    );
  }

  String _parseRequiredOrigin(
    String raw, {
    required String fieldName,
  }) {
    final uri = Uri.tryParse(raw);
    if (uri == null ||
        !uri.hasScheme ||
        (uri.scheme != 'http' && uri.scheme != 'https') ||
        uri.host.trim().isEmpty ||
        uri.userInfo.isNotEmpty ||
        (uri.path.isNotEmpty && uri.path != '/') ||
        uri.query.isNotEmpty ||
        uri.fragment.isNotEmpty) {
      throw StateError(
        'Invalid $fieldName: "$raw". '
        'Expected a full origin, e.g. http://192.168.0.10.nip.io:8081',
      );
    }

    if (_isIpLiteralHost(uri.host)) {
      throw StateError(
        '$fieldName host "${uri.host}" is IP-only and cannot resolve tenant subdomains. '
        'Use a wildcard DNS host such as http://192.168.0.10.nip.io:8081.',
      );
    }

    return _trimTrailingSlash(
      uri.replace(path: '', query: null, fragment: null).toString(),
    );
  }

  bool _isIpLiteralHost(String host) {
    final normalized = host.trim();
    if (normalized.isEmpty) {
      return false;
    }

    // IPv6 literals contain ':' in Uri.host form.
    if (normalized.contains(':')) {
      return true;
    }

    final ipv4Pattern = RegExp(r'^\d{1,3}(?:\.\d{1,3}){3}$');
    if (!ipv4Pattern.hasMatch(normalized)) {
      return false;
    }

    return normalized
        .split('.')
        .map(int.tryParse)
        .every((segment) => segment != null && segment >= 0 && segment <= 255);
  }

  String _trimTrailingSlash(String value) {
    return value.endsWith('/') ? value.substring(0, value.length - 1) : value;
  }
}

String responseLabel(int? statusCode) {
  if (statusCode == null) return 'status=unknown';
  return 'status=$statusCode';
}

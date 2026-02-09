import 'package:belluga_now/application/configurations/belluga_constants.dart';
import 'package:belluga_now/infrastructure/dal/dao/app_data_backend_contract.dart';
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
            connectTimeout: const Duration(seconds: 3),
            receiveTimeout: const Duration(seconds: 3),
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

      return AppDataDTO.fromJson(payload);
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
      final explicitUri = Uri.tryParse(explicit);
      if (explicitUri == null || explicitUri.host.trim().isEmpty) {
        throw StateError(
          'Invalid BOOTSTRAP_BASE_URL: "$explicit". '
          'Use a full origin, e.g. http://10.0.2.2:8081',
        );
      }
      return _trimTrailingSlash(explicit);
    }

    final landlordDomain = BellugaConstants.landlordDomain.trim();
    if (landlordDomain.isEmpty) {
      throw StateError(
        'Missing landlord bootstrap configuration. '
        'Provide BOOTSTRAP_BASE_URL or LANDLORD_DOMAIN via --dart-define '
        'or --dart-define-from-file (config/defines/<lane>.json).',
      );
    }

    final landlordUri = Uri.tryParse(landlordDomain);
    if (landlordUri != null && landlordUri.hasScheme) {
      if (landlordUri.host.trim().isEmpty) {
        throw StateError(
          'Invalid LANDLORD_DOMAIN: "$landlordDomain". '
          'Expected host (e.g. belluga.app) or full origin.',
        );
      }
      return _trimTrailingSlash(landlordDomain);
    }

    return _trimTrailingSlash(
        '${BellugaConstants.apiScheme}://$landlordDomain');
  }

  String _trimTrailingSlash(String value) {
    return value.endsWith('/') ? value.substring(0, value.length - 1) : value;
  }
}

String responseLabel(int? statusCode) {
  if (statusCode == null) return 'status=unknown';
  return 'status=$statusCode';
}

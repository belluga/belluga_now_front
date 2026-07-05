import 'package:belluga_now/application/configurations/belluga_constants.dart';
import 'package:belluga_now/infrastructure/dal/dao/app_data_backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/laravel_backend/app_data_backend/app_data_backend_http_fetcher.dart';
import 'package:belluga_now/infrastructure/dal/dto/app_data_dto.dart';
import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AppDataBackend implements AppDataBackendContract {
  AppDataBackend({Dio? dio}) : this._internal(dio);

  AppDataBackend._internal(this._dio);

  final Dio? _dio;

  @override
  Future<AppDataDTO> fetch() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final bootstrapBaseUrl = _resolveBootstrapBaseUrl();
    return fetchAppDataEnvironment(
      bootstrapBaseUrl: bootstrapBaseUrl,
      dio: _dio,
      appDomain: packageInfo.packageName.trim(),
    );
  }

  String _resolveBootstrapBaseUrl() {
    final explicit = BellugaConstants.bootstrapBaseUrlOverride.trim();
    if (explicit.isNotEmpty) {
      return _parseRequiredOrigin(explicit, fieldName: 'BOOTSTRAP_BASE_URL');
    }

    final landlordDomain = BellugaConstants.landlordDomain.trim();
    if (landlordDomain.isEmpty) {
      final injected = _dio?.options.baseUrl.trim() ?? '';
      if (injected.isNotEmpty) {
        return _parseRequiredOrigin(injected, fieldName: 'DIO_BASE_URL');
      }

      throw StateError(
        'Missing landlord bootstrap configuration. '
        'Provide BOOTSTRAP_BASE_URL or LANDLORD_DOMAIN via --dart-define '
        'or --dart-define-from-file (config/defines/<lane>.json).',
      );
    }

    return _parseRequiredOrigin(landlordDomain, fieldName: 'LANDLORD_DOMAIN');
  }

  String _parseRequiredOrigin(String raw, {required String fieldName}) {
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

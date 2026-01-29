import 'package:belluga_now/application/configurations/belluga_constants.dart';
import 'package:belluga_now/infrastructure/dal/dao/app_data_backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dto/app_data_dto.dart';
import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AppDataBackend implements AppDataBackendContract {
  AppDataBackend({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: 'https://${BellugaConstants.landlordDomain}',
              ),
            );

  final Dio _dio;

  @override
  Future<AppDataDTO> fetch() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final url =
        '/api/v1/environment?app_domain=${Uri.encodeComponent(packageInfo.packageName)}';

    try {
      final response = await _dio.get(url);
      final raw = response.data;
      final Map<String, dynamic> json;
      if (raw is Map<String, dynamic>) {
        json = (raw['data'] is Map<String, dynamic>)
            ? raw['data'] as Map<String, dynamic>
            : raw;
      } else {
        throw Exception(
          'Unexpected environment response shape for ${response.requestOptions.baseUrl}$url',
        );
      }
      return AppDataDTO.fromJson(json);
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
        'Could not retrieve branding data for ${_dio.options.baseUrl}$url: $e',
      );
    }
  }
}

String responseLabel(int? statusCode) {
  if (statusCode == null) return 'status=unknown';
  return 'status=$statusCode';
}

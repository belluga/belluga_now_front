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

    try {
      final response = await _dio.get(
        '/environment?app_domain=${packageInfo.packageName}',
      );
      final raw = response.data;
      final Map<String, dynamic> json;
      if (raw is Map<String, dynamic>) {
        json = (raw['data'] is Map<String, dynamic>)
            ? raw['data'] as Map<String, dynamic>
            : raw;
      } else {
        throw Exception('Unexpected environment response shape');
      }
      // Debug: log which URLs are being parsed from the payload.
      // Note: keep concise to avoid leaking sensitive data.
      // ignore: avoid_print
      print(
        '[AppDataBackend] Branding payload -> light_logo: ${json['main_logo_light_url']}, '
        'dark_logo: ${json['main_logo_dark_url']}, light_icon: ${json['main_icon_light_url']}, '
        'dark_icon: ${json['main_icon_dark_url']}',
      );
      return AppDataDTO.fromJson(json);
    } on DioException catch (e) {
      throw Exception('Failed to load environment data: ${e.message}');
    } catch (e) {
      throw Exception('Could not retrieve branding data.');
    }
  }
}

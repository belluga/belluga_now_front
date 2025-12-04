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
      return AppDataDTO.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception('Failed to load environment data: ${e.message}');
    } catch (e) {
      throw Exception('Could not retrieve branding data.');
    }
  }
}

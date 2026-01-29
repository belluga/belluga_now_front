import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:dio/dio.dart';

class BackendContext {
  BackendContext({
    required this.baseUrl,
    required this.adminUrl,
    Dio? dio,
  }) : dio = dio ?? Dio(BaseOptions(baseUrl: baseUrl));

  factory BackendContext.fromAppData(AppData appData) {
    final origin = Uri.parse(appData.href);
    return BackendContext(
      baseUrl: origin.resolve('/api').toString(),
      adminUrl: origin.resolve('/admin/api').toString(),
    );
  }

  final String baseUrl;
  final String adminUrl;
  final Dio dio;
}

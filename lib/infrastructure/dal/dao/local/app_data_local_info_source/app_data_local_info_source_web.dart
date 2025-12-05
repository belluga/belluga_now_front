import 'package:belluga_now/domain/app_data/app_type.dart';
import 'package:belluga_now/domain/app_data/value_object/platform_type_value.dart';
import 'package:web/web.dart' as web;

/// Local environment metadata for web targets (reads from window.location).
class AppDataLocalInfoSource {
  Future<Map<String, dynamic>> getInfo() async {
    final location = web.window.location;
    return {
      'platformType': PlatformTypeValue(defaultValue: AppType.web),
      'port': location.port,
      'hostname': location.hostname,
      'href': location.href,
      'device': 'web',
    };
  }
}

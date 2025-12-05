import 'package:belluga_now/application/configurations/belluga_constants.dart';
import 'package:belluga_now/domain/app_data/app_type.dart';
import 'package:belluga_now/domain/app_data/value_object/platform_type_value.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:platform_device_id_plus/platform_device_id.dart';

/// Local environment metadata for mobile/desktop targets.
class AppDataLocalInfoSource {
  Future<Map<String, dynamic>> getInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final deviceId = await PlatformDeviceId.getDeviceId ?? 'unkn';

    AppType platformType = AppType.mobile;
    final platformStr = BellugaConstants.settings.platform;
    if (platformStr == 'web') {
      platformType = AppType.web;
    } else if (['windows', 'macos', 'linux'].contains(platformStr)) {
      platformType = AppType.desktop;
    }

    return {
      'platformType': PlatformTypeValue(defaultValue: platformType),
      'port': packageInfo.version,
      'hostname': packageInfo.packageName,
      'href': packageInfo.appName,
      'device': '${BellugaConstants.settings.platform}_$deviceId',
    };
  }
}

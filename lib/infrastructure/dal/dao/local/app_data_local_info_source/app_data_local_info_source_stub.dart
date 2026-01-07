import 'package:belluga_now/application/configurations/belluga_constants.dart';
import 'package:belluga_now/domain/app_data/app_type.dart';
import 'package:belluga_now/domain/app_data/value_object/platform_type_value.dart';
import 'package:belluga_now/infrastructure/repositories/auth_repository.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Local environment metadata for mobile/desktop targets.
class AppDataLocalInfoSource {
  Future<Map<String, dynamic>> getInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();

    AppType platformType = AppType.mobile;
    final platformStr = BellugaConstants.settings.platform;
    if (platformStr == 'web') {
      platformType = AppType.web;
    } else if (['windows', 'macos', 'linux'].contains(platformStr)) {
      platformType = AppType.desktop;
    }

    final platformTypeValue = PlatformTypeValue(defaultValue: platformType)
      ..parse(platformType.name);

    final deviceId = await AuthRepository.ensureDeviceId();
    return {
      'platformType': platformTypeValue,
      'port': packageInfo.version,
      'hostname': packageInfo.packageName,
      'href': packageInfo.appName,
      // NOTE: Avoid `platform_device_id_*` plugins to keep Flutter Web WASM builds compatible.
      // We rely on a generated device id stored in secure storage instead.
      'device': deviceId,
    };
  }
}

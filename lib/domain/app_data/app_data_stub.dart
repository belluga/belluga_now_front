import 'package:belluga_now/application/configurations/belluga_constants.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:platform_device_id_plus/platform_device_id.dart';

class AppData {
  late String? port;
  late String hostname;
  late String href;
  late String device;

  Future<void> initialize() async {
    final packageInfo = await PackageInfo.fromPlatform();

    final deviceId = await PlatformDeviceId.getDeviceId ?? "unkn";

    port = packageInfo.version;
    hostname = packageInfo.packageName;
    href = packageInfo.appName;
    device = "${BellugaConstants.settings.platform}_$deviceId";
  }

  String get schema => href.split(hostname).first;

  @override
  String toString() {
    return 'Tenant(port: $port, hostname: $hostname, href: $href, device: $device)';
  }
}

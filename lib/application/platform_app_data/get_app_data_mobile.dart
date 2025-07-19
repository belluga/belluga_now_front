import 'package:package_info_plus/package_info_plus.dart';
import 'package:belluga_now/application/app_data.dart';

Future<AppData> getPlatformAppData() async {
  final packageInfo = await PackageInfo.fromPlatform();
  return AppData(
    port: packageInfo.version,
    hostname: packageInfo.packageName,
    href: packageInfo.appName,
  );
}

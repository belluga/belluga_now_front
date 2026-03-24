import 'package:belluga_now/domain/app_data/app_type.dart';
import 'package:belluga_now/domain/app_data/value_object/platform_type_value.dart';

class AppDataLocalInfoDTO {
  const AppDataLocalInfoDTO({
    required this.platformTypeValue,
    required this.port,
    required this.hostname,
    required this.href,
    required this.device,
  });

  final PlatformTypeValue platformTypeValue;
  final String? port;
  final String hostname;
  final String href;
  final String device;

  factory AppDataLocalInfoDTO.fromLegacyMap(Map<String, dynamic> raw) {
    final platformTypeValue =
        raw['platformType'] is PlatformTypeValue
            ? raw['platformType'] as PlatformTypeValue
            : (PlatformTypeValue(defaultValue: AppType.mobile)
              ..parse(AppType.mobile.name));

    return AppDataLocalInfoDTO(
      platformTypeValue: platformTypeValue,
      port: raw['port']?.toString(),
      hostname: raw['hostname']?.toString() ?? '',
      href: raw['href']?.toString() ?? '',
      device: raw['device']?.toString() ?? '',
    );
  }
}

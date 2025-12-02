import 'package:belluga_now/domain/app_data/app_type.dart';
import 'package:value_object_pattern/value_object.dart';

class EnvironmentTypeValue extends ValueObject<AppType> {
  EnvironmentTypeValue({
    super.defaultValue = AppType.mobile,
    super.isRequired = false,
  });

  @override
  AppType doParse(dynamic value) {
    if (value is String) {
      if (value == 'tenant') {
        return AppType.mobile; // Mapping tenant to mobile for now as per stub
      } else {
        return AppType.mobile;
      }
    }
    return defaultValue;
  }
}

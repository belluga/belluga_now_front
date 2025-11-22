import 'package:belluga_now/domain/app_data/app_type.dart';
import 'package:value_object_pattern/value_object.dart';

class PlatformTypeValue extends ValueObject<AppType> {
  PlatformTypeValue({
    super.defaultValue = AppType.mobile,
    super.isRequired = false,
  });

  @override
  AppType doParse(dynamic value) {
    if (value is AppType) return value;
    return defaultValue;
  }
}

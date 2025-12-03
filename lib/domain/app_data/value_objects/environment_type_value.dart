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
      switch (value) {
        case 'tenant':
        case 'landlord':
        case 'mobile':
          return AppType.mobile;
        case 'web':
          return AppType.web;
        case 'desktop':
          return AppType.desktop;
      }
    }
    return defaultValue;
  }
}

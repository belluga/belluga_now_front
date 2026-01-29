import 'package:belluga_now/domain/app_data/environment_type.dart';
import 'package:value_object_pattern/value_object.dart';

class EnvironmentTypeValue extends ValueObject<EnvironmentType> {
  EnvironmentTypeValue({
    super.defaultValue = EnvironmentType.landlord,
    super.isRequired = true,
  });

  @override
  EnvironmentType doParse(String? parseValue) {
    final fallback = defaultValue;
    if (parseValue == null) {
      return fallback;
    }
    return EnvironmentType.values.firstWhere(
      (value) => value.name == parseValue,
      orElse: () => fallback,
    );
  }
}

import 'package:belluga_now/domain/app_data/platform_type.dart';
import 'package:value_object_pattern/value_object.dart';

class PlatformTypeValue extends ValueObject<PlatformType?> {
  PlatformTypeValue({
    super.defaultValue,
    super.isRequired = true,
  });

  @override
  PlatformType doParse(String? parseValue) =>
      PlatformType.values.byName(parseValue!);
}

import 'package:value_object_pattern/domain/value_objects/date_time_value.dart';

class PoiUpdatedAtValue extends DateTimeValue {
  PoiUpdatedAtValue({
    super.defaultValue,
    super.isRequired = true,
  });
}

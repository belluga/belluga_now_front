import 'package:value_object_pattern/domain/value_objects/generic_string_value.dart';

class ScheduleEventIdValue extends GenericStringValue {
  ScheduleEventIdValue({
    super.defaultValue = '',
    super.isRequired = true,
  });
}

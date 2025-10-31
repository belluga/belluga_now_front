import 'package:belluga_now/domain/schedule/event_action_types.dart';
import 'package:value_object_pattern/value_object.dart';

class EventActionTypeValue extends ValueObject<EventActionTypes?> {
  EventActionTypeValue({
    super.defaultValue,
    super.isRequired = true,
  });

  @override
  EventActionTypes doParse(String? parseValue) {
    return EventActionTypes.values.byName(parseValue!);
  }
}

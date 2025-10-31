import 'package:belluga_now/domain/schedule/event_action_item_types.dart';
import 'package:value_object_pattern/value_object.dart';

class EventActionItemTypeValue extends ValueObject<EventActionItemTypes?> {
  EventActionItemTypeValue({
    super.defaultValue,
    super.isRequired = true,
  });

  @override
  EventActionItemTypes doParse(String? parseValue) {
    return EventActionItemTypes.values.byName(parseValue!);
  }
}

import 'package:belluga_now/domain/app_data/value_object/push_enabled_value.dart';
import 'package:belluga_now/domain/app_data/value_object/push_throttles_value.dart';
import 'package:belluga_now/domain/app_data/value_object/push_types_value.dart';

class PushSettings {
  PushSettings({
    required this.enabledValue,
    required this.typeValues,
    required this.throttlesValue,
  });

  final PushEnabledValue enabledValue;
  final PushTypesValue typeValues;
  final PushThrottlesValue throttlesValue;

  bool get enabled => enabledValue.value;
  List<String> get types => typeValues.value;
  Map<String, dynamic> get throttles => throttlesValue.value;
}

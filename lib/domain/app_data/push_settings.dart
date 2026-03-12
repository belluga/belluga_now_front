import 'package:belluga_now/domain/app_data/value_object/push_enabled_value.dart';
import 'package:belluga_now/domain/app_data/value_object/push_throttles_value.dart';
import 'package:belluga_now/domain/app_data/value_object/push_types_value.dart';

class PushSettings {
  PushSettings({
    required bool enabled,
    required List<String> types,
    required Map<String, dynamic> throttles,
  })  : enabledValue = _buildEnabledValue(enabled),
        typeValues = PushTypesValue(types),
        throttlesValue = PushThrottlesValue(throttles);

  final PushEnabledValue enabledValue;
  final PushTypesValue typeValues;
  final PushThrottlesValue throttlesValue;

  bool get enabled => enabledValue.value;
  List<String> get types => typeValues.value;
  Map<String, dynamic> get throttles => throttlesValue.value;

  static PushSettings? tryFromMap(Map<String, dynamic>? map) {
    if (map == null) return null;
    final enabled = map['enabled'];
    final typesRaw = map['types'];
    final throttlesRaw = map['throttles'];

    final parsedEnabled = enabled is bool ? enabled : false;
    final parsedTypes = (typesRaw is List)
        ? typesRaw.map((e) => e.toString()).toList(growable: false)
        : const <String>[];
    final parsedThrottles = throttlesRaw is Map<String, dynamic>
        ? Map<String, dynamic>.unmodifiable(throttlesRaw)
        : const <String, dynamic>{};

    return PushSettings(
      enabled: parsedEnabled,
      types: parsedTypes,
      throttles: parsedThrottles,
    );
  }

  static PushEnabledValue _buildEnabledValue(bool raw) {
    final value = PushEnabledValue()..parse(raw.toString());
    return value;
  }
}

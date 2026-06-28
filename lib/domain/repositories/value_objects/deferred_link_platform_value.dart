import 'package:value_object_pattern/domain/value_objects/generic_string_value.dart';

class DeferredLinkPlatformValue extends GenericStringValue {
  DeferredLinkPlatformValue({
    super.defaultValue = '',
    super.isRequired = false,
  });

  factory DeferredLinkPlatformValue.fromRaw(
    Object? raw, {
    String defaultValue = '',
    bool isRequired = false,
  }) {
    final value = DeferredLinkPlatformValue(
      defaultValue: defaultValue,
      isRequired: isRequired,
    );
    value.parse(raw?.toString());
    return value;
  }

  @override
  String doParse(String? parseValue) {
    return (parseValue ?? '').trim();
  }
}

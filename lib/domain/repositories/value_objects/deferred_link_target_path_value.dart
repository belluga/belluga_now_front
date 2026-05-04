import 'package:value_object_pattern/domain/value_objects/generic_string_value.dart';

class DeferredLinkTargetPathValue extends GenericStringValue {
  DeferredLinkTargetPathValue({
    super.defaultValue = '',
    super.isRequired = false,
  });

  factory DeferredLinkTargetPathValue.fromRaw(
    Object? raw, {
    String defaultValue = '',
    bool isRequired = false,
  }) {
    final value = DeferredLinkTargetPathValue(
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

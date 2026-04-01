import 'package:value_object_pattern/domain/value_objects/generic_string_value.dart';

class DeferredLinkFailureReasonValue extends GenericStringValue {
  DeferredLinkFailureReasonValue({
    super.defaultValue = '',
    super.isRequired = false,
  });

  factory DeferredLinkFailureReasonValue.fromRaw(
    Object? raw, {
    String defaultValue = '',
    bool isRequired = false,
  }) {
    final value = DeferredLinkFailureReasonValue(
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

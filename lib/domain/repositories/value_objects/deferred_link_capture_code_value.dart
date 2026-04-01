import 'package:value_object_pattern/domain/value_objects/generic_string_value.dart';

class DeferredLinkCaptureCodeValue extends GenericStringValue {
  DeferredLinkCaptureCodeValue({
    super.defaultValue = '',
    super.isRequired = false,
  });

  factory DeferredLinkCaptureCodeValue.fromRaw(
    Object? raw, {
    String defaultValue = '',
    bool isRequired = false,
  }) {
    final value = DeferredLinkCaptureCodeValue(
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

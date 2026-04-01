import 'package:value_object_pattern/domain/value_objects/generic_string_value.dart';

class DeferredLinkStoreChannelValue extends GenericStringValue {
  DeferredLinkStoreChannelValue({
    super.defaultValue = '',
    super.isRequired = false,
  });

  factory DeferredLinkStoreChannelValue.fromRaw(
    Object? raw, {
    String defaultValue = '',
    bool isRequired = false,
  }) {
    final value = DeferredLinkStoreChannelValue(
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

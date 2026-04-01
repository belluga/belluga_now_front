import 'package:value_object_pattern/domain/value_objects/generic_string_value.dart';

class ProfileAvatarPathValue extends GenericStringValue {
  ProfileAvatarPathValue({
    super.defaultValue = '',
    super.isRequired = false,
    super.minLenght = 0,
  });

  factory ProfileAvatarPathValue.fromRaw(
    Object? raw, {
    String defaultValue = '',
    bool isRequired = false,
  }) {
    final value = ProfileAvatarPathValue(
      defaultValue: defaultValue,
      isRequired: isRequired,
      minLenght: 0,
    );
    value.parse(raw?.toString() ?? '');
    return value;
  }
}

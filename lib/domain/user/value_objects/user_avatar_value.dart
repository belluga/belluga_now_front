import 'package:value_object_pattern/domain/value_objects/uri_value.dart';

class UserAvatarValue extends URIValue {
  UserAvatarValue({
    super.defaultValue,
    super.isRequired = false,
  });
}

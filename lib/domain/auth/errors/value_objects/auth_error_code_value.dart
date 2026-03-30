import 'package:value_object_pattern/value_object.dart';

class AuthErrorCodeValue extends ValueObject<int> {
  AuthErrorCodeValue({
    Object? raw,
    super.defaultValue = 0,
    super.isRequired = false,
  }) {
    parse(raw?.toString());
  }

  @override
  int doParse(String? parseValue) {
    return int.tryParse(parseValue ?? '') ?? 0;
  }
}

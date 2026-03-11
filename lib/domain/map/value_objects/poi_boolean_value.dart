import 'package:value_object_pattern/domain/exceptions/value_exceptions.dart';
import 'package:value_object_pattern/value_object.dart';

class PoiBooleanValue extends ValueObject<bool> {
  PoiBooleanValue({
    super.defaultValue = false,
    super.isRequired = true,
  });

  @override
  bool doParse(String? parseValue) {
    switch (parseValue?.trim().toLowerCase()) {
      case 'true':
        return true;
      case 'false':
        return false;
      default:
        throw InvalidValueException();
    }
  }
}

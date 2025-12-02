import 'package:value_object_pattern/domain/exceptions/value_exceptions.dart';
import 'package:value_object_pattern/value_object.dart';

class DistanceInMetersValue extends ValueObject<double> {
  DistanceInMetersValue({
    super.defaultValue = 0,
    super.isRequired = false,
  });

  @override
  double doParse(String? parseValue) {
    if (parseValue == null || parseValue.isEmpty) {
      return defaultValue;
    }
    final parsed = double.tryParse(parseValue);
    if (parsed == null || parsed < 0) {
      throw InvalidValueException();
    }
    return parsed;
  }
}

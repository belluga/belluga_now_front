import 'package:value_object_pattern/domain/exceptions/value_exceptions.dart';
import 'package:value_object_pattern/value_object.dart';

class LatitudeValue extends ValueObject<double> {
  LatitudeValue({
    super.defaultValue = 0,
    super.isRequired = true,
  });

  @override
  double doParse(String? parseValue) {
    final parsed = double.tryParse(parseValue ?? '');
    if (parsed == null || parsed < -90 || parsed > 90) {
      throw InvalidValueException();
    }
    return parsed;
  }
}

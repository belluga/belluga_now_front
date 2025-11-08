import 'package:value_object_pattern/domain/exceptions/value_exceptions.dart';
import 'package:value_object_pattern/value_object.dart';

class LongitudeValue extends ValueObject<double> {
  LongitudeValue({
    super.defaultValue = 0,
    super.isRequired = true,
  });

  @override
  double doParse(String? parseValue) {
    final parsed = double.tryParse(parseValue ?? '');
    if (parsed == null || parsed < -180 || parsed > 180) {
      throw InvalidValueException();
    }
    return parsed;
  }
}

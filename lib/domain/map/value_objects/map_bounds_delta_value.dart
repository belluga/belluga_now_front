import 'package:value_object_pattern/domain/exceptions/value_exceptions.dart';
import 'package:value_object_pattern/value_object.dart';

class MapBoundsDeltaValue extends ValueObject<double> {
  MapBoundsDeltaValue({
    super.defaultValue = 0.08,
    super.isRequired = true,
  });

  @override
  double doParse(String? parseValue) {
    final parsed = double.tryParse(parseValue ?? '');
    if (parsed == null || parsed <= 0) {
      throw InvalidValueException();
    }
    return parsed;
  }
}

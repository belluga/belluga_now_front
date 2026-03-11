import 'package:value_object_pattern/domain/exceptions/value_exceptions.dart';
import 'package:value_object_pattern/value_object.dart';

class PoiStackCountValue extends ValueObject<int> {
  PoiStackCountValue({
    super.defaultValue = 1,
    super.isRequired = true,
  });

  @override
  int doParse(String? parseValue) {
    final parsed = int.tryParse(parseValue ?? '');
    if (parsed == null || parsed < 0) {
      throw InvalidValueException();
    }
    return parsed;
  }
}

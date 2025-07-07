import 'package:value_objects/domain/exceptions/value_exceptions.dart';
import 'package:value_objects/value_object.dart';

class ItemsTotalValue extends ValueObject<int> {
  ItemsTotalValue({super.defaultValue = 0, super.isRequired = true});

  @override
  int doParse(String? parseValue) {
    final _value = int.parse(parseValue!);
    if (_value < 0) {
      throw InvalidValueException();
    }

    return _value;
  }
}

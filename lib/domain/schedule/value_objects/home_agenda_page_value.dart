import 'package:value_object_pattern/domain/exceptions/value_exceptions.dart';
import 'package:value_object_pattern/value_object.dart';

class HomeAgendaPageValue extends ValueObject<int> {
  HomeAgendaPageValue({
    super.defaultValue = 1,
    super.isRequired = true,
  });

  @override
  int doParse(dynamic parseValue) {
    if (parseValue is int && parseValue >= 0) {
      return parseValue;
    }
    if (parseValue is String) {
      final parsed = int.tryParse(parseValue);
      if (parsed != null && parsed >= 0) {
        return parsed;
      }
    }
    throw InvalidValueException();
  }
}

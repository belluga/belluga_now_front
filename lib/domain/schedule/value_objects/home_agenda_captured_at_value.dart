import 'package:value_object_pattern/domain/exceptions/value_exceptions.dart';
import 'package:value_object_pattern/value_object.dart';

class HomeAgendaCapturedAtValue extends ValueObject<DateTime> {
  HomeAgendaCapturedAtValue({
    required super.defaultValue,
    super.isRequired = true,
  });

  @override
  DateTime doParse(dynamic parseValue) {
    if (parseValue is DateTime) {
      return parseValue;
    }
    if (parseValue is String) {
      final parsed = DateTime.tryParse(parseValue);
      if (parsed != null) {
        return parsed;
      }
    }
    throw InvalidValueException();
  }
}

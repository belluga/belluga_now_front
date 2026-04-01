import 'package:value_object_pattern/value_object.dart';

class DomainOptionalDateTimeValue extends ValueObject<DateTime?> {
  DomainOptionalDateTimeValue({
    super.defaultValue,
    super.isRequired = false,
  });

  @override
  DateTime? doParse(dynamic parseValue) {
    if (parseValue == null) {
      return null;
    }
    if (parseValue is DateTime) {
      return parseValue;
    }
    return DateTime.tryParse(parseValue.toString());
  }
}

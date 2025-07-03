import 'package:value_objects/domain/exceptions/value_exceptions.dart';
import 'package:value_objects/value_object.dart';

class URIRequiredValue extends ValueObject<Uri> {
  URIRequiredValue({required super.defaultValue, super.isRequired = true});

  @override
  Uri doParse(String? parseValue) =>
      Uri.parse(parseValue ?? defaultValue.toString());

  @override
  void validate(String? newValue) {
    super.validate(newValue);

    final uri = Uri.parse(newValue!);
    if (uri.isAbsolute == false) {
      throw InvalidValueException();
    }
  }
}

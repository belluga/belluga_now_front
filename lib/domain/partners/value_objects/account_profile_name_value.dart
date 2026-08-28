import 'package:value_object_pattern/domain/exceptions/value_exceptions.dart';
import 'package:value_object_pattern/domain/value_objects/generic_string_value.dart';

class AccountProfileNameValue extends GenericStringValue {
  static const int minimumLength = 3;
  static const int maximumLength = 255;

  AccountProfileNameValue({super.defaultValue = '', super.isRequired = true});

  @override
  String doParse(String? parseValue) => (parseValue ?? '').trim();

  @override
  void validate(String? newValue) {
    final normalized = doParse(newValue);
    if (normalized.isEmpty) {
      throw RequiredValueException();
    }
    if (normalized.runes.length < minimumLength) {
      throw TooShortValueException();
    }
    if (normalized.runes.length > maximumLength) {
      throw TooLongValueException();
    }
  }
}

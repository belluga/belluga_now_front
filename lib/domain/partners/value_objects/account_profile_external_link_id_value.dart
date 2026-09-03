import 'package:value_object_pattern/domain/exceptions/value_exceptions.dart';
import 'package:value_object_pattern/value_object.dart';

final class AccountProfileExternalLinkIdValue extends ValueObject<String> {
  AccountProfileExternalLinkIdValue(String raw)
    : super(defaultValue: '', isRequired: true) {
    parse(raw);
  }

  @override
  String doParse(String? parseValue) {
    final value = parseValue?.trim() ?? '';
    if (value.isEmpty) throw InvalidValueException();
    return value;
  }
}

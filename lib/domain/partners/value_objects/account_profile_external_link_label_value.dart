import 'package:value_object_pattern/domain/exceptions/value_exceptions.dart';
import 'package:value_object_pattern/value_object.dart';

final class AccountProfileExternalLinkLabelValue extends ValueObject<String> {
  AccountProfileExternalLinkLabelValue(String raw)
    : super(defaultValue: '', isRequired: true) {
    parse(raw);
  }

  @override
  String doParse(String? parseValue) {
    final value = parseValue?.trim() ?? '';
    if (value.isEmpty || value.length > 255) throw InvalidValueException();
    return value;
  }
}

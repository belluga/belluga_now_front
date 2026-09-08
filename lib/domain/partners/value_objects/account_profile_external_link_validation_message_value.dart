import 'package:value_object_pattern/value_object.dart';

final class AccountProfileExternalLinkValidationMessageValue
    extends ValueObject<String> {
  AccountProfileExternalLinkValidationMessageValue(String message)
    : super(defaultValue: '', isRequired: true) {
    parse(message);
  }

  @override
  String doParse(String? parseValue) => parseValue ?? '';
}

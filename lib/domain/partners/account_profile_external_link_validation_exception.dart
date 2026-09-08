import 'package:belluga_now/domain/partners/value_objects/account_profile_external_link_validation_message_value.dart';

enum AccountProfileExternalLinkValidationField { id, url, label }

final class AccountProfileExternalLinkValidationException implements Exception {
  AccountProfileExternalLinkValidationException({
    required this.field,
    required this.messageValue,
  });

  final AccountProfileExternalLinkValidationField field;
  final AccountProfileExternalLinkValidationMessageValue messageValue;

  String get message => messageValue.value;

  @override
  String toString() => message;
}

import 'package:belluga_now/domain/auth/errors/value_objects/auth_error_field_name_value.dart';
import 'package:belluga_now/domain/auth/errors/value_objects/auth_error_message_value.dart';

class AuthErrorFieldIssue {
  AuthErrorFieldIssue({
    required this.fieldNameValue,
    List<AuthErrorMessageValue> messages = const [],
  }) : messages = List<AuthErrorMessageValue>.unmodifiable(messages);

  final AuthErrorFieldNameValue fieldNameValue;
  final List<AuthErrorMessageValue> messages;

  String get fieldName => fieldNameValue.value;

  AuthErrorMessageValue? get primaryMessageValue {
    if (messages.isEmpty) {
      return null;
    }
    return messages.first;
  }
}

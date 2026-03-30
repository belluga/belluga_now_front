import 'package:belluga_now/domain/auth/errors/value_objects/auth_error_code_value.dart';
import 'package:belluga_now/domain/auth/errors/value_objects/auth_error_message_value.dart';
import 'package:belluga_now/domain/auth/errors/auth_error_field_issue.dart';

export 'package:belluga_now/domain/auth/errors/value_objects/auth_error_code_value.dart';
export 'package:belluga_now/domain/auth/errors/value_objects/auth_error_field_name_value.dart';
export 'package:belluga_now/domain/auth/errors/value_objects/auth_error_message_value.dart';
export 'package:belluga_now/domain/auth/errors/auth_error_field_issue.dart';

part 'auth_error_email.dart';
part 'auth_error_generic.dart';
part 'auth_error_invalid_credentials.dart';
part 'auth_error_invalid_token.dart';
part 'auth_error_password.dart';
part 'auth_error_user_already_exists.dart';
part 'auth_error_validation.dart';
part 'auth_error_validation_error.dart';

sealed class BellugaAuthError {
  final AuthErrorMessageValue messageValue;

  BellugaAuthError({
    AuthErrorMessageValue? message,
  }) : messageValue = message ?? AuthErrorMessageValue(raw: 'Erro desconhecido');

  String get message => messageValue.value;

  factory BellugaAuthError.fromCode({
    AuthErrorCodeValue? errorCode,
    AuthErrorMessageValue? message,
    AuthErrorFieldIssue? fieldIssue,
  }) {
    final BellugaAuthError error = switch (errorCode?.value) {
      403 => AuthErrorInvalidCredentials(),
      409 => AuthErrorUserAlreadyExists(),
      401 => AuthErrorInvalidToken(),
      422 => AuthErrorValidationError.fromErrors(
          fieldIssue: fieldIssue,
        ),
      _ => AuthErrorGeneric(
          message: message,
        ),
    };

    return error;
  }
}

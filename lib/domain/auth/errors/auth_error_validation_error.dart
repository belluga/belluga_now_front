part of 'belluga_auth_errors.dart';

class AuthErrorValidationError extends BellugaAuthError {
  AuthErrorValidationError({AuthErrorMessageValue? message})
      : super(
            message:
                message ?? AuthErrorMessageValue(raw: 'Erro de validação'));

  factory AuthErrorValidationError.fromErrors({
    AuthErrorFieldIssue? fieldIssue,
  }) {
    final message =
        fieldIssue?.primaryMessageValue ?? AuthErrorMessageValue(raw: 'Erro de validação');

    final AuthErrorValidationError error = switch (fieldIssue?.fieldName) {
      'password' => AuthErrorPassword(message: message),
      'email' => AuthErrorEmail(message: message),
      _ => AuthErrorValidationError(message: message),
    };

    return error;
  }
}

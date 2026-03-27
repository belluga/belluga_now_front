part of 'belluga_auth_errors.dart';

class AuthErrorValidationError extends BellugaAuthError {
  AuthErrorValidationError({AuthErrorMessageValue? message})
      : super(message: message ?? const AuthErrorMessageValue('Erro de validação'));

  factory AuthErrorValidationError.fromErrors({
    AuthErrorPayloadValue errors = const AuthErrorPayloadValue(),
  }) {
    final errorsPayload = errors.value;
    final firstErrorList = errorsPayload.values.isEmpty
        ? const <dynamic>[]
        : (errorsPayload.values.first as List<dynamic>? ?? const <dynamic>[]);
    final firstMessage =
        firstErrorList.isEmpty ? 'Erro de validação' : firstErrorList.first.toString();
    final message = AuthErrorMessageValue(firstMessage);

    final firstKey = errorsPayload.keys.isEmpty ? null : errorsPayload.keys.first;
    final AuthErrorValidationError error = switch (firstKey) {
      'password' => AuthErrorPassword(message: message),
      'email' => AuthErrorEmail(message: message),
      _ => AuthErrorValidationError(message: message),
    };

    return error;
  }
}

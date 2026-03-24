part of 'belluga_auth_errors.dart';

typedef AuthValidationErrorPayload = Map<String, dynamic>;

class AuthErrorValidationError extends BellugaAuthError {
  AuthErrorValidationError({super.message = 'Erro de validação'});

  factory AuthErrorValidationError.fromErrors({
    AuthValidationErrorPayload errors = const <String, dynamic>{},
  }) {
    final message = errors.values.first.first;

    final AuthErrorValidationError error = switch (errors.keys.first) {
      'password' => AuthErrorPassword(message: message),
      'email' => AuthErrorEmail(message: message),
      _ => AuthErrorValidationError(message: message),
    };

    return error;
  }
}

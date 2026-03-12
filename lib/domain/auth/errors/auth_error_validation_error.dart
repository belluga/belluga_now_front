part of 'belluga_auth_errors.dart';

class AuthErrorValidationError extends BellugaAuthError {
  AuthErrorValidationError({super.message = 'Erro de validação'});

  factory AuthErrorValidationError.fromErrors({
    Map<String, dynamic> errors = const <String, dynamic>{},
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

sealed class BellugaAuthError {
  final String message;
  final Map<String, List<String>> errors;

  BellugaAuthError(
      {this.message = "Erro desconhecido", this.errors = const {}});

  factory BellugaAuthError.fromCode(
      {int? errorCode, String? message, Map<String, dynamic>? errors}) {
    final BellugaAuthError _error = switch (errorCode) {
      403 => AuthErrorInvalidCredentials(),
      409 => AuthErrorUserAlreadyExists(),
      401 => AuthErrorInvalidToken(),
      422 => AuthErrorValidationError.fromErrors(
          errors: errors ?? {},
        ),
      _ => AuthErrorGeneric(),
    };

    return _error;
  }
}

final class AuthErrorUserAlreadyExists extends BellugaAuthError {
  AuthErrorUserAlreadyExists() : super(message: "Usuário já existe");
}

final class AuthErrorValidation extends BellugaAuthError {
  AuthErrorValidation({required super.message});
}

final class AuthErrorGeneric extends BellugaAuthError {
  AuthErrorGeneric() : super(message: "Erro não identificado");
}

final class AuthErrorInvalidCredentials extends BellugaAuthError {
  AuthErrorInvalidCredentials() : super(message: "Usuário ou senha inválidos");
}

final class AuthErrorInvalidToken extends BellugaAuthError {
  AuthErrorInvalidToken() : super(message: "Token inválido");
}

class AuthErrorValidationError extends BellugaAuthError {
  AuthErrorValidationError({super.message = "Erro de validação"});

  factory AuthErrorValidationError.fromErrors(
      {Map<String, dynamic> errors = const {}}) {
    final String message = errors.values.first.first;

    final AuthErrorValidationError _error = switch (errors.keys.first) {
      'password' => AuthErrorPassword(message: message),
      'email' => AuthErrorEmail(message: message),
      _ => AuthErrorValidationError(message: message),
    };

    return _error;
  }
}

final class AuthErrorPassword extends AuthErrorValidationError {
  AuthErrorPassword({required super.message});
}

final class AuthErrorEmail extends AuthErrorValidationError {
  AuthErrorEmail({required super.message});
}

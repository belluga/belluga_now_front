part of 'belluga_auth_errors.dart';

final class AuthErrorInvalidToken extends BellugaAuthError {
  AuthErrorInvalidToken()
      : super(message: AuthErrorMessageValue(raw: 'Token inválido'));
}

part of 'belluga_auth_errors.dart';

final class AuthErrorInvalidCredentials extends BellugaAuthError {
  AuthErrorInvalidCredentials()
      : super(
            message: AuthErrorMessageValue(raw: 'Usuário ou senha inválidos'));
}

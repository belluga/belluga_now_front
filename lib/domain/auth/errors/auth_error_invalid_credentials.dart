part of 'belluga_auth_errors.dart';

final class AuthErrorInvalidCredentials extends BellugaAuthError {
  AuthErrorInvalidCredentials()
      : super(message: const AuthErrorMessageValue('Usuário ou senha inválidos'));
}

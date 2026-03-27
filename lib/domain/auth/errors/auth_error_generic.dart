part of 'belluga_auth_errors.dart';

final class AuthErrorGeneric extends BellugaAuthError {
  AuthErrorGeneric()
      : super(message: const AuthErrorMessageValue('Erro não identificado'));
}

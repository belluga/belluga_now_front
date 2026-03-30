part of 'belluga_auth_errors.dart';

final class AuthErrorGeneric extends BellugaAuthError {
  AuthErrorGeneric({AuthErrorMessageValue? message})
      : super(message: message ?? AuthErrorMessageValue(raw: 'Erro não identificado'));
}

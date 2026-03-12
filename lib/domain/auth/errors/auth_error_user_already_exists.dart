part of 'belluga_auth_errors.dart';

final class AuthErrorUserAlreadyExists extends BellugaAuthError {
  AuthErrorUserAlreadyExists() : super(message: 'Usuário já existe');
}

part 'auth_error_email.dart';
part 'auth_error_generic.dart';
part 'auth_error_invalid_credentials.dart';
part 'auth_error_invalid_token.dart';
part 'auth_error_password.dart';
part 'auth_error_user_already_exists.dart';
part 'auth_error_validation.dart';
part 'auth_error_validation_error.dart';

typedef AuthErrorCode = int;
typedef AuthErrorMessageText = String;
typedef AuthErrorFieldKey = String;
typedef AuthErrorFieldText = String;
typedef AuthErrorFieldMessages
    = Map<AuthErrorFieldKey, List<AuthErrorFieldText>>;
typedef AuthErrorPayload = Map<String, dynamic>;

sealed class BellugaAuthError {
  final AuthErrorMessageText message;
  final AuthErrorFieldMessages errors;

  BellugaAuthError({
    this.message = 'Erro desconhecido',
    this.errors = const {},
  });

  factory BellugaAuthError.fromCode({
    AuthErrorCode? errorCode,
    AuthErrorMessageText? message,
    AuthErrorPayload? errors,
  }) {
    final BellugaAuthError error = switch (errorCode) {
      403 => AuthErrorInvalidCredentials(),
      409 => AuthErrorUserAlreadyExists(),
      401 => AuthErrorInvalidToken(),
      422 => AuthErrorValidationError.fromErrors(
          errors: errors ?? const <AuthErrorFieldKey, dynamic>{},
        ),
      _ => AuthErrorGeneric(),
    };

    return error;
  }
}

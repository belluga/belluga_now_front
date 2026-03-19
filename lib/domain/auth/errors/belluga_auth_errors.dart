part 'auth_error_email.dart';
part 'auth_error_generic.dart';
part 'auth_error_invalid_credentials.dart';
part 'auth_error_invalid_token.dart';
part 'auth_error_password.dart';
part 'auth_error_user_already_exists.dart';
part 'auth_error_validation.dart';
part 'auth_error_validation_error.dart';

sealed class BellugaAuthError {
  final String message;
  final Map<String, List<String>> errors;

  BellugaAuthError({
    this.message = 'Erro desconhecido',
    this.errors = const {},
  });

  factory BellugaAuthError.fromCode({
    int? errorCode,
    String? message,
    Map<String, dynamic>? errors,
  }) {
    final BellugaAuthError error = switch (errorCode) {
      403 => AuthErrorInvalidCredentials(),
      409 => AuthErrorUserAlreadyExists(),
      401 => AuthErrorInvalidToken(),
      422 => AuthErrorValidationError.fromErrors(
          errors: errors ?? const <String, dynamic>{},
        ),
      _ => AuthErrorGeneric(),
    };

    return error;
  }
}

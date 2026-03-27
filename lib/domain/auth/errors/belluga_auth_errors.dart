part 'auth_error_email.dart';
part 'auth_error_generic.dart';
part 'auth_error_invalid_credentials.dart';
part 'auth_error_invalid_token.dart';
part 'auth_error_password.dart';
part 'auth_error_user_already_exists.dart';
part 'auth_error_validation.dart';
part 'auth_error_validation_error.dart';

class AuthErrorCodeValue {
  const AuthErrorCodeValue(this.value);

  final int? value;
}

class AuthErrorMessageValue {
  const AuthErrorMessageValue(this.value);

  final String value;
}

class AuthErrorFieldMessagesValue {
  const AuthErrorFieldMessagesValue([Map<String, List<String>>? value])
      : value = value ?? const <String, List<String>>{};

  final Map<String, List<String>> value;
}

class AuthErrorPayloadValue {
  const AuthErrorPayloadValue([Map<String, dynamic>? value])
      : value = value ?? const <String, dynamic>{};

  final Map<String, dynamic> value;
}

sealed class BellugaAuthError {
  final AuthErrorMessageValue messageValue;
  final AuthErrorFieldMessagesValue errorsValue;

  BellugaAuthError({
    AuthErrorMessageValue? message,
    AuthErrorFieldMessagesValue? errors,
  })  : messageValue = message ?? const AuthErrorMessageValue('Erro desconhecido'),
        errorsValue = errors ?? const AuthErrorFieldMessagesValue();

  String get message => messageValue.value;
  Map<String, List<String>> get errors => errorsValue.value;

  factory BellugaAuthError.fromCode({
    AuthErrorCodeValue? errorCode,
    AuthErrorMessageValue? message,
    AuthErrorPayloadValue? errors,
  }) {
    final BellugaAuthError error = switch (errorCode?.value) {
      403 => AuthErrorInvalidCredentials(),
      409 => AuthErrorUserAlreadyExists(),
      401 => AuthErrorInvalidToken(),
      422 => AuthErrorValidationError.fromErrors(
          errors: errors ?? const AuthErrorPayloadValue(),
        ),
      _ => AuthErrorGeneric(),
    };

    return error;
  }
}

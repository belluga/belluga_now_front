export 'auth_repository_contract_text_value.dart';

import 'auth_repository_contract_text_value.dart';

AuthRepositoryContractTextValue authRepoString(
  Object? raw, {
  String defaultValue = '',
  bool isRequired = true,
}) {
  if (raw is AuthRepositoryContractTextValue) {
    return raw;
  }
  return AuthRepositoryContractTextValue.fromRaw(
    raw,
    defaultValue: defaultValue,
    isRequired: isRequired,
  );
}

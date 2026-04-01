export 'landlord_auth_repository_contract_text_value.dart';

import 'landlord_auth_repository_contract_text_value.dart';

LandlordAuthRepositoryContractTextValue landlordAuthRepoString(
  Object? raw, {
  String defaultValue = '',
  bool isRequired = true,
}) {
  if (raw is LandlordAuthRepositoryContractTextValue) {
    return raw;
  }
  return LandlordAuthRepositoryContractTextValue.fromRaw(
    raw,
    defaultValue: defaultValue,
    isRequired: isRequired,
  );
}

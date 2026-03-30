export 'user_events_repository_contract_bool_value.dart';
export 'user_events_repository_contract_text_value.dart';

import 'user_events_repository_contract_bool_value.dart';
import 'user_events_repository_contract_text_value.dart';

UserEventsRepositoryContractTextValue userEventsRepoString(
  Object? raw, {
  String defaultValue = '',
  bool isRequired = true,
}) {
  if (raw is UserEventsRepositoryContractTextValue) {
    return raw;
  }
  return UserEventsRepositoryContractTextValue.fromRaw(
    raw,
    defaultValue: defaultValue,
    isRequired: isRequired,
  );
}

UserEventsRepositoryContractBoolValue userEventsRepoBool(
  Object? raw, {
  bool defaultValue = false,
  bool isRequired = true,
}) {
  if (raw is UserEventsRepositoryContractBoolValue) {
    return raw;
  }
  return UserEventsRepositoryContractBoolValue.fromRaw(
    raw,
    defaultValue: defaultValue,
    isRequired: isRequired,
  );
}

export 'invites_repository_contract_bool_value.dart';
export 'invites_repository_contract_collections.dart';
export 'invites_repository_contract_int_value.dart';
export 'invites_repository_contract_text_value.dart';

import 'invites_repository_contract_bool_value.dart';
import 'invites_repository_contract_int_value.dart';
import 'invites_repository_contract_text_value.dart';

InvitesRepositoryContractTextValue invitesRepoString(
  Object? raw, {
  String defaultValue = '',
  bool isRequired = true,
}) {
  if (raw is InvitesRepositoryContractTextValue) {
    return raw;
  }
  return InvitesRepositoryContractTextValue.fromRaw(
    raw,
    defaultValue: defaultValue,
    isRequired: isRequired,
  );
}

InvitesRepositoryContractIntValue invitesRepoInt(
  Object? raw, {
  int defaultValue = 0,
  bool isRequired = true,
}) {
  if (raw is InvitesRepositoryContractIntValue) {
    return raw;
  }
  return InvitesRepositoryContractIntValue.fromRaw(
    raw,
    defaultValue: defaultValue,
    isRequired: isRequired,
  );
}

InvitesRepositoryContractBoolValue invitesRepoBool(
  Object? raw, {
  bool defaultValue = false,
  bool isRequired = true,
}) {
  if (raw is InvitesRepositoryContractBoolValue) {
    return raw;
  }
  return InvitesRepositoryContractBoolValue.fromRaw(
    raw,
    defaultValue: defaultValue,
    isRequired: isRequired,
  );
}

import 'package:belluga_now/domain/partners/account_profile_nested_group_member.dart';
import 'package:belluga_now/domain/partners/value_objects/account_profile_nested_group_fields.dart';

export 'package:belluga_now/domain/partners/account_profile_nested_group_member.dart';
export 'package:belluga_now/domain/partners/value_objects/account_profile_nested_group_fields.dart';

class AccountProfileNestedGroup {
  AccountProfileNestedGroup({
    required this.idValue,
    required this.labelValue,
    required this.orderValue,
    List<AccountProfileNestedGroupMember>? profiles,
  }) : profiles = profiles ?? const <AccountProfileNestedGroupMember>[];

  final AccountProfileNestedGroupIdValue idValue;
  final AccountProfileNestedGroupLabelValue labelValue;
  final AccountProfileNestedGroupOrderValue orderValue;
  final List<AccountProfileNestedGroupMember> profiles;

  String get id => idValue.value;
  String get label => labelValue.value;
  int get order => orderValue.value;
  bool get isVisible => label.trim().isNotEmpty && profiles.isNotEmpty;
}

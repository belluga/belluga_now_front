import 'package:belluga_now/domain/partners/account_profile_nested_group_member.dart';
import 'package:belluga_now/domain/partners/value_objects/account_profile_nested_group_member_text_value.dart';

class AccountProfileNestedGroupMemberPage {
  const AccountProfileNestedGroupMemberPage.empty()
    : items = const <AccountProfileNestedGroupMember>[],
      nextCursorValue = null;

  AccountProfileNestedGroupMemberPage({
    required List<AccountProfileNestedGroupMember> items,
    required this.nextCursorValue,
  }) : items = List<AccountProfileNestedGroupMember>.unmodifiable(items);

  final List<AccountProfileNestedGroupMember> items;
  final AccountProfileNestedGroupMemberTextValue? nextCursorValue;

  bool get hasMore => (nextCursorValue?.value.trim() ?? '').isNotEmpty;
}

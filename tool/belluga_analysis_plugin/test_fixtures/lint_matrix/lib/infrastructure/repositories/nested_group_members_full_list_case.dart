class NestedGroupMembersFullListCase {
  // expect_lint: nested_group_members_full_list_forbidden
  Future<List<String>> fetchNestedGroupMembersByPath(String path) async => [];

  // expect_no_lint: nested_group_members_full_list_forbidden
  Future<List<String>> fetchNestedGroupMembersPageByPath(String path) async =>
      [];

  Future<List<String>> drainPages(String path) async {
    final items = <String>[];
    // expect_lint: nested_group_members_full_list_forbidden
    while (items.isEmpty) {
      items.addAll(await fetchNestedGroupMembersPageByPath(path));
    }
    return items;
  }
}

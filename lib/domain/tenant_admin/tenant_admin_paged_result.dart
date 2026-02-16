class TenantAdminPagedResult<T> {
  const TenantAdminPagedResult({
    required this.items,
    required this.hasMore,
  });

  final List<T> items;
  final bool hasMore;
}

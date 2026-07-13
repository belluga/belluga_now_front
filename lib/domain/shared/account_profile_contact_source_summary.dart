class AccountProfileContactSourceSummary {
  const AccountProfileContactSourceSummary({
    required this.id,
    required this.displayName,
    this.slug,
    required this.profileType,
  });

  final String id;
  final String displayName;
  final String? slug;
  final String profileType;
}

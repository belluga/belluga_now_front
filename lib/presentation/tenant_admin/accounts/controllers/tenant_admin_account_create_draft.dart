class TenantAdminAccountCreateDraft {
  const TenantAdminAccountCreateDraft({required this.selectedProfileType});

  factory TenantAdminAccountCreateDraft.initial() =>
      const TenantAdminAccountCreateDraft(selectedProfileType: null);

  final String? selectedProfileType;

  TenantAdminAccountCreateDraft copyWith({String? selectedProfileType}) {
    return TenantAdminAccountCreateDraft(
      selectedProfileType: selectedProfileType ?? this.selectedProfileType,
    );
  }
}

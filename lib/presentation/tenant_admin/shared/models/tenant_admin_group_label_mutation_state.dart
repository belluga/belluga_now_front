class TenantAdminGroupLabelMutationState {
  static const maxLabelLength = 255;
  const TenantAdminGroupLabelMutationState({
    required this.draft,
    this.isEditing = false,
    this.isLoading = false,
    this.errorText,
  });

  final String draft;
  final bool isEditing;
  final bool isLoading;
  final String? errorText;

  bool get hasError => errorText?.trim().isNotEmpty ?? false;
}

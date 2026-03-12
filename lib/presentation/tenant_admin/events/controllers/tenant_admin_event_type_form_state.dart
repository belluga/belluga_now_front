class TenantAdminEventTypeFormState {
  static const Object _undefined = Object();

  const TenantAdminEventTypeFormState({
    required this.isEdit,
    required this.isSlugAutoEnabled,
    required this.isSaving,
    required this.formError,
  });

  factory TenantAdminEventTypeFormState.initial() {
    return const TenantAdminEventTypeFormState(
      isEdit: false,
      isSlugAutoEnabled: true,
      isSaving: false,
      formError: null,
    );
  }

  final bool isEdit;
  final bool isSlugAutoEnabled;
  final bool isSaving;
  final String? formError;

  TenantAdminEventTypeFormState copyWith({
    bool? isEdit,
    bool? isSlugAutoEnabled,
    bool? isSaving,
    Object? formError = _undefined,
  }) {
    return TenantAdminEventTypeFormState(
      isEdit: isEdit ?? this.isEdit,
      isSlugAutoEnabled: isSlugAutoEnabled ?? this.isSlugAutoEnabled,
      isSaving: isSaving ?? this.isSaving,
      formError:
          formError == _undefined ? this.formError : formError as String?,
    );
  }
}

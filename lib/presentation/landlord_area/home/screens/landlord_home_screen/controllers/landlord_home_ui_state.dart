class LandlordHomeUiState {
  const LandlordHomeUiState({
    required this.tenants,
    required this.hasValidSession,
    required this.isLandlordMode,
  });

  factory LandlordHomeUiState.initial() => const LandlordHomeUiState(
        tenants: <String>[],
        hasValidSession: false,
        isLandlordMode: false,
      );

  final List<String> tenants;
  final bool hasValidSession;
  final bool isLandlordMode;

  bool get canAccessAdminArea => hasValidSession && isLandlordMode;
}

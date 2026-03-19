class InitScreenUiState {
  static const _unset = Object();

  const InitScreenUiState({
    required this.errorMessage,
    required this.isRetrying,
  });

  factory InitScreenUiState.initial() =>
      const InitScreenUiState(errorMessage: null, isRetrying: false);

  final String? errorMessage;
  final bool isRetrying;

  InitScreenUiState copyWith({
    Object? errorMessage = _unset,
    bool? isRetrying,
  }) {
    final nextErrorMessage =
        errorMessage == _unset ? this.errorMessage : errorMessage as String?;
    return InitScreenUiState(
      errorMessage: nextErrorMessage,
      isRetrying: isRetrying ?? this.isRetrying,
    );
  }
}

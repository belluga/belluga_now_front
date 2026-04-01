class AgendaRadiusSheetPresentation {
  const AgendaRadiusSheetPresentation({
    required this.title,
    required this.description,
    this.helperText,
    this.confirmButtonLabel,
  });

  final String title;
  final String description;
  final String? helperText;
  final String? confirmButtonLabel;

  bool get requiresExplicitConfirmation => confirmButtonLabel != null;
}

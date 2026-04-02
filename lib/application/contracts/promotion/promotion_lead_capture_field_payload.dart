class PromotionLeadCaptureFieldPayload {
  PromotionLeadCaptureFieldPayload({
    required String label,
    required String value,
  })  : label = label.trim(),
        value = value.trim();

  final String label;
  final String value;
}

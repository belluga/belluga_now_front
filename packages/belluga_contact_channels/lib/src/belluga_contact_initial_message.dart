class BellugaContactInitialMessage {
  const BellugaContactInitialMessage({
    required this.id,
    required this.cta,
    required this.message,
  });

  final String id;
  final String cta;
  final String message;

  BellugaContactInitialMessage copyWith({
    String? id,
    String? cta,
    String? message,
  }) {
    return BellugaContactInitialMessage(
      id: id ?? this.id,
      cta: cta ?? this.cta,
      message: message ?? this.message,
    );
  }
}

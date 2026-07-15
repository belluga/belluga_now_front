enum BellugaContactChannelType {
  email('email'),
  whatsapp('whatsapp');

  const BellugaContactChannelType(this.rawValue);

  final String rawValue;

  static BellugaContactChannelType? fromRaw(String? raw) {
    final normalized = raw?.trim().toLowerCase();
    for (final type in values) {
      if (type.rawValue == normalized) {
        return type;
      }
    }
    return null;
  }
}

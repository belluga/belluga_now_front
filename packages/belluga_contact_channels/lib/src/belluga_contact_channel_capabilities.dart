/// Behaviour declared by a contact-channel definition.
///
/// These are intentionally independent flags: message presets belong to the
/// channel that declares them, while [bubble] merely controls eligibility for
/// the one floating quick-entry selection on an account profile.
class BellugaContactChannelCapabilities {
  const BellugaContactChannelCapabilities({
    required this.publicCard,
    required this.directLaunch,
    required this.bubble,
    required this.messagePresets,
    required this.repeatable,
    required this.maxInitialMessages,
    required this.maxInitialMessageCtaLength,
    required this.maxInitialMessageLength,
  });

  final bool publicCard;
  final bool directLaunch;
  final bool bubble;
  final bool messagePresets;
  final bool repeatable;
  final int maxInitialMessages;
  final int maxInitialMessageCtaLength;
  final int maxInitialMessageLength;
}

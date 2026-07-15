import 'belluga_contact_channel_type.dart';

class BellugaContactResolution {
  const BellugaContactResolution({
    required this.type,
    required this.uri,
    required this.normalizedTarget,
    this.prefilledMessage,
  });

  final BellugaContactChannelType type;
  final Uri uri;
  final String normalizedTarget;
  final String? prefilledMessage;
}

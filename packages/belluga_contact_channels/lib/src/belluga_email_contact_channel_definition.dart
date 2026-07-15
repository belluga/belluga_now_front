part of 'belluga_contact_channel_definitions.dart';

final class BellugaEmailContactChannelDefinition
    implements BellugaContactChannelDefinition {
  const BellugaEmailContactChannelDefinition();

  static final RegExp _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  @override
  BellugaContactChannelType get type => BellugaContactChannelType.email;

  @override
  String get canonicalLabel => 'E-mail';

  @override
  BellugaContactIconToken get iconToken =>
      BellugaContactIconToken.emailOutlined;

  @override
  BellugaContactChannelCapabilities get capabilities =>
      const BellugaContactChannelCapabilities(
        publicCard: true,
        directLaunch: true,
        bubble: false,
        messagePresets: false,
        repeatable: true,
        maxInitialMessages: 0,
        maxInitialMessageCtaLength: 0,
        maxInitialMessageLength: 0,
      );

  @override
  String? normalizeValue(String rawValue) {
    final normalized = rawValue.trim().toLowerCase();
    return normalized.isNotEmpty && _emailPattern.hasMatch(normalized)
        ? normalized
        : null;
  }

  @override
  BellugaContactResolution? resolveLaunch(
    String rawValue, {
    String? prefilledMessage,
  }) {
    final normalized = normalizeValue(rawValue);
    if (normalized == null) return null;
    final body = _trimToNullable(prefilledMessage);
    final encodedTarget = Uri.encodeComponent(normalized);
    final encodedBody = body == null ? null : Uri.encodeComponent(body);
    return BellugaContactResolution(
      type: type,
      uri: Uri.parse(
        'mailto:$encodedTarget${encodedBody == null ? '' : '?body=$encodedBody'}',
      ),
      normalizedTarget: normalized,
      prefilledMessage: body,
    );
  }

  @override
  List<BellugaContactInitialMessage> decodeInitialMessages(
          Object? rawMetadata) =>
      const <BellugaContactInitialMessage>[];

  @override
  Map<String, dynamic> encodeMetadata(
    List<BellugaContactInitialMessage> initialMessages,
  ) =>
      const <String, dynamic>{};
}

String? _trimToNullable(String? raw) {
  final trimmed = raw?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}

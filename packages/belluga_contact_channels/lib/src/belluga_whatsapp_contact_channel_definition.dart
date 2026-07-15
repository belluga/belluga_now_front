part of 'belluga_contact_channel_definitions.dart';

final class BellugaWhatsAppContactChannelDefinition
    implements BellugaContactChannelDefinition {
  const BellugaWhatsAppContactChannelDefinition();

  static const int _maxInitialMessages = 20;
  static const int _maxInitialMessageCtaLength = 255;
  static const int _maxInitialMessageLength = 1000;

  @override
  BellugaContactChannelType get type => BellugaContactChannelType.whatsapp;

  @override
  String get canonicalLabel => 'WhatsApp';

  @override
  BellugaContactIconToken get iconToken => BellugaContactIconToken.whatsapp;

  @override
  BellugaContactChannelCapabilities get capabilities =>
      const BellugaContactChannelCapabilities(
        publicCard: true,
        directLaunch: true,
        bubble: true,
        messagePresets: true,
        repeatable: true,
        maxInitialMessages: _maxInitialMessages,
        maxInitialMessageCtaLength: _maxInitialMessageCtaLength,
        maxInitialMessageLength: _maxInitialMessageLength,
      );

  @override
  String? normalizeValue(String rawValue) {
    final normalized = rawValue.trim();
    return _targetDigits(normalized) == null ? null : normalized;
  }

  @override
  BellugaContactResolution? resolveLaunch(
    String rawValue, {
    String? prefilledMessage,
  }) {
    final digits = _targetDigits(rawValue);
    if (digits == null) return null;
    final message = _trimToNullable(prefilledMessage);
    final encodedMessage =
        message == null ? null : Uri.encodeComponent(message);
    return BellugaContactResolution(
      type: type,
      uri: Uri.parse(
        'https://wa.me/$digits${encodedMessage == null ? '' : '?text=$encodedMessage'}',
      ),
      normalizedTarget: digits,
      prefilledMessage: message,
    );
  }

  @override
  List<BellugaContactInitialMessage> decodeInitialMessages(
      Object? rawMetadata) {
    if (rawMetadata is! Map) return const <BellugaContactInitialMessage>[];
    final rawMessages = rawMetadata['initial_messages'];
    if (rawMessages is! List) return const <BellugaContactInitialMessage>[];
    final limits = capabilities;
    final messages = <BellugaContactInitialMessage>[];
    final seenIds = <String>{};
    for (final rawMessage in rawMessages) {
      if (rawMessage is! Map) continue;
      final id = rawMessage['id']?.toString().trim() ?? '';
      final cta = rawMessage['cta']?.toString().trim() ?? '';
      final message = rawMessage['mensagem']?.toString().trim() ?? '';
      if (messages.length >= limits.maxInitialMessages ||
          id.isEmpty ||
          cta.isEmpty ||
          cta.length > limits.maxInitialMessageCtaLength ||
          message.isEmpty ||
          message.length > limits.maxInitialMessageLength ||
          !seenIds.add(id)) {
        continue;
      }
      messages.add(
          BellugaContactInitialMessage(id: id, cta: cta, message: message));
    }
    return List<BellugaContactInitialMessage>.unmodifiable(messages);
  }

  @override
  Map<String, dynamic> encodeMetadata(
    List<BellugaContactInitialMessage> initialMessages,
  ) {
    if (initialMessages.isEmpty) return const <String, dynamic>{};
    return <String, dynamic>{
      'initial_messages': initialMessages
          .map(
            (message) => <String, dynamic>{
              'id': message.id.trim(),
              'cta': message.cta.trim(),
              'mensagem': message.message.trim(),
            },
          )
          .toList(growable: false),
    };
  }

  String? _targetDigits(String rawValue) {
    final trimmed = rawValue.trim();
    if (trimmed.isEmpty) return null;
    final uri = Uri.tryParse(trimmed);
    if (uri != null && uri.hasScheme) {
      final host = uri.host.toLowerCase().trim();
      if (host == 'wa.me') {
        final digits = uri.pathSegments
            .map((segment) => segment.replaceAll(RegExp(r'[^0-9]'), ''))
            .join();
        return _isValidDigits(digits) ? digits : null;
      }
      if (host == 'api.whatsapp.com') {
        final digits = (uri.queryParameters['phone'] ?? '')
            .replaceAll(RegExp(r'[^0-9]'), '');
        return _isValidDigits(digits) ? digits : null;
      }
      return null;
    }
    final digits = trimmed.replaceAll(RegExp(r'[^0-9]'), '');
    return _isValidDigits(digits) ? digits : null;
  }

  bool _isValidDigits(String digits) =>
      digits.length >= 10 && digits.length <= 15;
}

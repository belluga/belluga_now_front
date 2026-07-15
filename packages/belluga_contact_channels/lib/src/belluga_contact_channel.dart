import 'belluga_contact_channel_definition.dart';
import 'belluga_contact_channel_registry.dart';
import 'belluga_contact_channel_type.dart';
import 'belluga_contact_icon_token.dart';
import 'belluga_contact_initial_message.dart';

class BellugaContactChannel {
  BellugaContactChannel({
    required this.id,
    required this.type,
    required this.value,
    this.title,
    List<BellugaContactInitialMessage> initialMessages = const [],
  }) : initialMessages = List<BellugaContactInitialMessage>.unmodifiable(
          initialMessages,
        );

  final String id;
  final BellugaContactChannelType type;
  final String value;
  final String? title;
  final List<BellugaContactInitialMessage> initialMessages;

  BellugaContactChannelDefinition get definition =>
      BellugaContactChannelRegistry.canonical.require(type);

  bool get isBubbleEligible => definition.capabilities.bubble;
  bool get supportsInitialMessages => definition.capabilities.messagePresets;
  bool get hasInitialMessages => initialMessages.isNotEmpty;

  BellugaContactIconToken get iconToken => definition.iconToken;

  BellugaContactChannel copyWith({
    String? id,
    BellugaContactChannelType? type,
    String? value,
    String? title,
    List<BellugaContactInitialMessage>? initialMessages,
  }) {
    return BellugaContactChannel(
      id: id ?? this.id,
      type: type ?? this.type,
      value: value ?? this.value,
      title: title ?? this.title,
      initialMessages: initialMessages ?? this.initialMessages,
    );
  }
}

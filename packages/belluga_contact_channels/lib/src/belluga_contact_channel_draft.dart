import 'belluga_contact_channel.dart';
import 'belluga_contact_channel_definition.dart';
import 'belluga_contact_channel_registry.dart';
import 'belluga_contact_channel_type.dart';
import 'belluga_contact_initial_message.dart';

/// Client-only authoring state. Persisted channel ids are optional because the
/// server owns generated identities for new channels; [draftKey] is request
/// local and lets an atomic bubble selection refer to a new channel.
class BellugaContactChannelDraft {
  BellugaContactChannelDraft({
    required this.draftKey,
    required this.type,
    required this.value,
    this.id,
    this.title,
    List<BellugaContactInitialMessage> initialMessages = const [],
  }) : initialMessages =
            List<BellugaContactInitialMessage>.unmodifiable(initialMessages);

  factory BellugaContactChannelDraft.fromChannel(
          BellugaContactChannel channel) =>
      BellugaContactChannelDraft(
        draftKey: 'persisted:${channel.id}',
        id: channel.id,
        type: channel.type,
        value: channel.value,
        title: channel.title,
        initialMessages: channel.initialMessages,
      );

  final String draftKey;
  final String? id;
  final BellugaContactChannelType type;
  final String value;
  final String? title;
  final List<BellugaContactInitialMessage> initialMessages;

  bool get isPersisted => id?.trim().isNotEmpty ?? false;
  BellugaContactChannelDefinition get definition =>
      BellugaContactChannelRegistry.canonical.require(type);

  BellugaContactChannelDraft copyWith({
    String? id,
    BellugaContactChannelType? type,
    String? value,
    Object? title = _unset,
    List<BellugaContactInitialMessage>? initialMessages,
  }) =>
      BellugaContactChannelDraft(
        draftKey: draftKey,
        id: id ?? this.id,
        type: type ?? this.type,
        value: value ?? this.value,
        title: identical(title, _unset) ? this.title : title as String?,
        initialMessages: initialMessages ?? this.initialMessages,
      );

  static const Object _unset = Object();
}

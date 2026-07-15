import 'belluga_contact_channel.dart';
import 'belluga_contact_channel_draft.dart';
import 'belluga_contact_channel_registry.dart';
import 'belluga_contact_channel_type.dart';
import 'belluga_contact_initial_message.dart';

final class BellugaContactChannelCodec {
  BellugaContactChannelCodec._();

  static BellugaContactChannel? channelFromJson(Object? raw) {
    if (raw is! Map) {
      return null;
    }
    final json = Map<String, dynamic>.from(raw);
    final id = json['id']?.toString().trim() ?? '';
    final type = BellugaContactChannelType.fromRaw(json['type']?.toString());
    final value = json['value']?.toString().trim() ?? '';
    if (id.isEmpty || type == null || value.isEmpty) {
      return null;
    }
    final title = _trimToNullable(json['title']?.toString());
    final metadata = json['metadata'];
    final metadataMap = metadata is Map<String, dynamic>
        ? metadata
        : (metadata is Map ? Map<String, dynamic>.from(metadata) : null);
    final definition = BellugaContactChannelRegistry.canonical.require(type);
    final initialMessages = definition.decodeInitialMessages(metadataMap);
    return BellugaContactChannel(
      id: id,
      type: type,
      value: value,
      title: title,
      initialMessages: initialMessages,
    );
  }

  static List<BellugaContactChannel> channelsFromJson(Object? raw) {
    if (raw is! List) {
      return const <BellugaContactChannel>[];
    }
    return raw
        .map(channelFromJson)
        .whereType<BellugaContactChannel>()
        .toList(growable: false);
  }

  static Map<String, dynamic> channelToJson(BellugaContactChannel channel) {
    return <String, dynamic>{
      'id': channel.id,
      'type': channel.type.rawValue,
      'value': channel.value,
      if (_trimToNullable(channel.title) case final title?) 'title': title,
      if (channel.definition.encodeMetadata(channel.initialMessages)
          case final metadata when metadata.isNotEmpty)
        'metadata': metadata,
    };
  }

  static List<Map<String, dynamic>> channelsToJson(
    List<BellugaContactChannel> channels,
  ) {
    return channels.map(channelToJson).toList(growable: false);
  }

  static Map<String, dynamic> draftToJson(BellugaContactChannelDraft draft) {
    final metadata = draft.definition.encodeMetadata(draft.initialMessages);
    return <String, dynamic>{
      if (draft.isPersisted) 'id': draft.id!.trim(),
      if (!draft.isPersisted) 'draft_key': draft.draftKey.trim(),
      'type': draft.type.rawValue,
      'value': draft.value.trim(),
      if (_trimToNullable(draft.title) case final title?) 'title': title,
      if (metadata.isNotEmpty) 'metadata': metadata,
    };
  }

  static List<Map<String, dynamic>> draftsToJson(
    List<BellugaContactChannelDraft> drafts,
  ) =>
      drafts.map(draftToJson).toList(growable: false);

  static List<BellugaContactInitialMessage> initialMessagesFromJson(
    Object? raw,
  ) {
    if (raw is! List) {
      return const <BellugaContactInitialMessage>[];
    }
    final items = <BellugaContactInitialMessage>[];
    for (final entry in raw) {
      if (entry is! Map) {
        continue;
      }
      final json = Map<String, dynamic>.from(entry);
      final id = json['id']?.toString().trim() ?? '';
      final cta = json['cta']?.toString().trim() ?? '';
      final message = json['mensagem']?.toString().trim() ?? '';
      if (id.isEmpty || cta.isEmpty || message.isEmpty) {
        continue;
      }
      items.add(
        BellugaContactInitialMessage(id: id, cta: cta, message: message),
      );
    }
    return List<BellugaContactInitialMessage>.unmodifiable(items);
  }

  static Map<String, dynamic> initialMessageToJson(
    BellugaContactInitialMessage message,
  ) {
    return <String, dynamic>{
      'id': message.id,
      'cta': message.cta,
      'mensagem': message.message,
    };
  }

  static String? _trimToNullable(String? raw) {
    final trimmed = raw?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }
}

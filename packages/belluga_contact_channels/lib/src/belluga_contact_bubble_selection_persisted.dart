part of 'belluga_contact_bubble_selection_mutation.dart';

final class BellugaContactBubbleSelectionPersisted
    extends BellugaContactBubbleSelectionMutation {
  BellugaContactBubbleSelectionPersisted(String channelId)
      : channelId = _required(channelId, 'channelId');

  final String channelId;

  @override
  void encodeInto(Map<String, dynamic> payload) {
    payload['contact_bubble_channel_id'] = channelId;
  }
}

part of 'belluga_contact_bubble_selection_mutation.dart';

final class BellugaContactBubbleSelectionClear
    extends BellugaContactBubbleSelectionMutation {
  const BellugaContactBubbleSelectionClear();

  @override
  void encodeInto(Map<String, dynamic> payload) {
    payload['contact_bubble_channel_id'] = null;
  }
}

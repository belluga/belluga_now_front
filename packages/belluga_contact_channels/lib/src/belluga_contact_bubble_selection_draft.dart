part of 'belluga_contact_bubble_selection_mutation.dart';

final class BellugaContactBubbleSelectionDraft
    extends BellugaContactBubbleSelectionMutation {
  BellugaContactBubbleSelectionDraft(String draftKey)
      : draftKey = _required(draftKey, 'draftKey');

  final String draftKey;

  @override
  void encodeInto(Map<String, dynamic> payload) {
    payload['contact_bubble_channel_draft_key'] = draftKey;
  }
}

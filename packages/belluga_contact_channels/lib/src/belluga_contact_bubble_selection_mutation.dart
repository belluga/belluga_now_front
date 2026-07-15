part 'belluga_contact_bubble_selection_clear.dart';
part 'belluga_contact_bubble_selection_draft.dart';
part 'belluga_contact_bubble_selection_omit.dart';
part 'belluga_contact_bubble_selection_persisted.dart';

/// Exact PATCH intent for the Account Profile bubble pointer.
sealed class BellugaContactBubbleSelectionMutation {
  const BellugaContactBubbleSelectionMutation();

  const factory BellugaContactBubbleSelectionMutation.omit() =
      BellugaContactBubbleSelectionOmit;
  const factory BellugaContactBubbleSelectionMutation.clear() =
      BellugaContactBubbleSelectionClear;
  factory BellugaContactBubbleSelectionMutation.setPersisted(String channelId) =
      BellugaContactBubbleSelectionPersisted;
  factory BellugaContactBubbleSelectionMutation.setDraft(String draftKey) =
      BellugaContactBubbleSelectionDraft;

  void encodeInto(Map<String, dynamic> payload);
}

String _required(String value, String field) {
  final normalized = value.trim();
  if (normalized.isEmpty) {
    throw ArgumentError.value(value, field, 'must not be blank');
  }
  return normalized;
}

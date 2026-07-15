import 'belluga_contact_channel_draft.dart';

/// Client-side parity guard for collection invariants that are also enforced
/// authoritatively by Laravel.
final class BellugaContactChannelDraftValidator {
  BellugaContactChannelDraftValidator._();

  static const int maxChannels = 20;

  static List<String> validate(List<BellugaContactChannelDraft> drafts) {
    final errors = <String>[];
    if (drafts.length > maxChannels) {
      errors.add('São permitidos no máximo $maxChannels canais de contato.');
    }
    final seenDraftKeys = <String>{};
    final counts = <Object, int>{};
    for (final draft in drafts) {
      if (!seenDraftKeys.add(draft.draftKey.trim())) {
        errors.add('Cada rascunho de canal precisa de uma chave única.');
      }
      counts[draft.type] = (counts[draft.type] ?? 0) + 1;
      if (!draft.isPersisted && draft.draftKey.trim().isEmpty) {
        errors.add('Um novo canal precisa de uma chave de rascunho.');
      }
      if (draft.definition.normalizeValue(draft.value) == null) {
        errors.add(
            '${draft.definition.canonicalLabel} precisa de um valor válido.');
      }
    }
    for (final draft in drafts) {
      final limits = draft.definition.capabilities;
      if (draft.initialMessages.length > limits.maxInitialMessages) {
        errors.add(
          '${draft.definition.canonicalLabel} permite no máximo ${limits.maxInitialMessages} CTAs.',
        );
      }
      if ((counts[draft.type] ?? 0) > 1 &&
          (draft.title?.trim().isEmpty ?? true)) {
        errors.add(
            'Todo ${draft.definition.canonicalLabel} repetido precisa de título.');
      }
      final ids = <String>{};
      var hasInvalidCta = false;
      var hasInvalidMessage = false;
      var hasDuplicateId = false;
      for (final message in draft.initialMessages) {
        if (!hasInvalidCta &&
            (message.cta.trim().isEmpty ||
                message.cta.trim().length >
                    limits.maxInitialMessageCtaLength)) {
          errors.add(
            'As CTAs de ${draft.definition.canonicalLabel} precisam ter até ${limits.maxInitialMessageCtaLength} caracteres.',
          );
          hasInvalidCta = true;
        }
        if (!hasInvalidMessage &&
            (message.message.trim().isEmpty ||
                message.message.trim().length >
                    limits.maxInitialMessageLength)) {
          errors.add(
            'As mensagens de ${draft.definition.canonicalLabel} precisam ter até ${limits.maxInitialMessageLength} caracteres.',
          );
          hasInvalidMessage = true;
        }
        if (!hasDuplicateId && !ids.add(message.id.trim())) {
          errors.add(
              'As CTAs de ${draft.definition.canonicalLabel} precisam de ids únicos.');
          hasDuplicateId = true;
        }
      }
    }
    return List<String>.unmodifiable(errors);
  }
}

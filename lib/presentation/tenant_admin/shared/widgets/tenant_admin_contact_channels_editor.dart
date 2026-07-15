import 'package:belluga_contact_channels/belluga_contact_channels.dart';
import 'package:flutter/material.dart';

/// Pure authoring UI for repeatable, definition-backed contact channels.
/// Contact state and mutations stay in the account-profile controller.
class TenantAdminContactChannelsEditor extends StatelessWidget {
  const TenantAdminContactChannelsEditor({
    super.key,
    required this.drafts,
    required this.bubbleSelection,
    required this.expandedCtaDraftKey,
    required this.onAddChannel,
    required this.onUpdateChannel,
    required this.onRemoveChannel,
    required this.onSelectBubble,
    required this.onToggleCtaEditor,
    required this.onAddInitialMessage,
    required this.onUpdateInitialMessage,
    required this.onRemoveInitialMessage,
  });

  final List<BellugaContactChannelDraft> drafts;
  final BellugaContactBubbleSelectionMutation bubbleSelection;
  final String? expandedCtaDraftKey;
  final ValueChanged<BellugaContactChannelType> onAddChannel;
  final ValueChanged<BellugaContactChannelDraft> onUpdateChannel;
  final ValueChanged<String> onRemoveChannel;
  final void Function(BellugaContactChannelDraft draft, bool selected)
  onSelectBubble;
  final ValueChanged<String> onToggleCtaEditor;
  final ValueChanged<String> onAddInitialMessage;
  final void Function(String draftKey, BellugaContactInitialMessage message)
  onUpdateInitialMessage;
  final void Function(String draftKey, String messageId) onRemoveInitialMessage;

  @override
  Widget build(BuildContext context) {
    final selectedBubbleDraftKey = _selectedBubbleDraftKey();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (drafts.isEmpty)
          const Text('Nenhum canal de contato configurado.')
        else
          ...drafts.map(
            (draft) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildChannelCard(
                context,
                draft,
                selectedBubbleDraftKey,
                expandedCtaDraftKey == draft.draftKey,
              ),
            ),
          ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: BellugaContactChannelRegistry.canonical.definitions
              .where((definition) => definition.capabilities.repeatable)
              .map(
                (definition) => OutlinedButton.icon(
                  key: Key(
                    'tenantAdminAddContactChannel_${definition.type.rawValue}',
                  ),
                  onPressed: () => onAddChannel(definition.type),
                  icon: const Icon(Icons.add),
                  label: Text('Adicionar ${definition.canonicalLabel}'),
                ),
              )
              .toList(growable: false),
        ),
      ],
    );
  }

  Widget _buildChannelCard(
    BuildContext context,
    BellugaContactChannelDraft draft,
    String? selectedBubbleDraftKey,
    bool isCtaEditorExpanded,
  ) {
    final definition = draft.definition;
    return Card(
      key: Key('tenantAdminContactChannelCard_${draft.draftKey}'),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_iconFor(definition.iconToken)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    definition.canonicalLabel,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Remover canal',
                  onPressed: () => onRemoveChannel(draft.draftKey),
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            TextFormField(
              key: Key('tenantAdminContactChannelValue_${draft.draftKey}'),
              initialValue: draft.value,
              keyboardType: definition.type == BellugaContactChannelType.email
                  ? TextInputType.emailAddress
                  : TextInputType.phone,
              decoration: InputDecoration(
                labelText: '${definition.canonicalLabel} de contato',
              ),
              onChanged: (value) =>
                  onUpdateChannel(draft.copyWith(value: value)),
              validator: (value) {
                final raw = value?.trim() ?? '';
                if (raw.isEmpty) return 'Informe um contato.';
                return definition.normalizeValue(raw) == null
                    ? 'Informe um ${definition.canonicalLabel} válido.'
                    : null;
              },
            ),
            const SizedBox(height: 8),
            TextFormField(
              key: Key('tenantAdminContactChannelTitle_${draft.draftKey}'),
              initialValue: draft.title,
              decoration: InputDecoration(
                labelText: 'Título de ${definition.canonicalLabel} (opcional)',
              ),
              onChanged: (value) => onUpdateChannel(
                draft.copyWith(title: value.trim().isEmpty ? null : value),
              ),
            ),
            if (definition.capabilities.bubble) ...[
              const SizedBox(height: 4),
              SwitchListTile(
                key: Key('tenantAdminContactBubbleToggle_${draft.draftKey}'),
                contentPadding: EdgeInsets.zero,
                title: const Text('Ativar balão flutuante'),
                value: selectedBubbleDraftKey == draft.draftKey,
                onChanged: (selected) => onSelectBubble(draft, selected),
              ),
            ],
            if (definition.capabilities.messagePresets) ...[
              const Divider(height: 24),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  key: Key(
                    'tenantAdminContactToggleCtaEditor_${draft.draftKey}',
                  ),
                  onPressed: () => onToggleCtaEditor(draft.draftKey),
                  icon: Icon(
                    isCtaEditorExpanded ? Icons.expand_less : Icons.expand_more,
                  ),
                  label: Text(
                    isCtaEditorExpanded ? 'Ocultar CTAs' : 'Editar CTAs',
                  ),
                ),
              ),
              if (isCtaEditorExpanded) ...[
                const SizedBox(height: 12),
                Text(
                  'CTAs e mensagens',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                ...draft.initialMessages.map(
                  (message) =>
                      _buildInitialMessageEditor(context, draft, message),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    key: Key('tenantAdminContactAddCta_${draft.draftKey}'),
                    onPressed:
                        draft.initialMessages.length >=
                            definition.capabilities.maxInitialMessages
                        ? null
                        : () => onAddInitialMessage(draft.draftKey),
                    icon: const Icon(Icons.add),
                    label: const Text('Adicionar CTA'),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInitialMessageEditor(
    BuildContext context,
    BellugaContactChannelDraft draft,
    BellugaContactInitialMessage message,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                tooltip: 'Remover CTA',
                onPressed: () =>
                    onRemoveInitialMessage(draft.draftKey, message.id),
                icon: const Icon(Icons.delete_outline),
              ),
            ),
            TextFormField(
              key: Key('tenantAdminContactCta_${draft.draftKey}_${message.id}'),
              initialValue: message.cta,
              maxLength:
                  draft.definition.capabilities.maxInitialMessageCtaLength,
              buildCounter:
                  (
                    _, {
                    required currentLength,
                    required isFocused,
                    maxLength,
                  }) => null,
              decoration: const InputDecoration(labelText: 'CTA'),
              onChanged: (cta) => onUpdateInitialMessage(
                draft.draftKey,
                message.copyWith(cta: cta),
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              key: Key(
                'tenantAdminContactMessage_${draft.draftKey}_${message.id}',
              ),
              initialValue: message.message,
              maxLength: draft.definition.capabilities.maxInitialMessageLength,
              buildCounter:
                  (
                    _, {
                    required currentLength,
                    required isFocused,
                    maxLength,
                  }) => null,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Mensagem'),
              onChanged: (text) => onUpdateInitialMessage(
                draft.draftKey,
                message.copyWith(message: text),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  String? _selectedBubbleDraftKey() {
    for (final draft in drafts) {
      if (bubbleSelection is BellugaContactBubbleSelectionPersisted &&
          draft.id ==
              (bubbleSelection as BellugaContactBubbleSelectionPersisted)
                  .channelId) {
        return draft.draftKey;
      }
      if (bubbleSelection is BellugaContactBubbleSelectionDraft &&
          draft.draftKey ==
              (bubbleSelection as BellugaContactBubbleSelectionDraft)
                  .draftKey) {
        return draft.draftKey;
      }
    }
    return null;
  }

  IconData _iconFor(BellugaContactIconToken token) => switch (token) {
    BellugaContactIconToken.emailOutlined => Icons.email_outlined,
    BellugaContactIconToken.whatsapp => Icons.chat_outlined,
  };
}

import 'package:flutter/material.dart';

enum TenantAdminImageUploadVariant { avatar, cover }

class TenantAdminImageUploadField extends StatelessWidget {
  const TenantAdminImageUploadField({
    super.key,
    required this.variant,
    required this.preview,
    required this.addLabel,
    required this.onAdd,
    required this.busy,
    required this.canRemove,
    required this.onRemove,
    this.selectedLabel,
    this.removeLabel = 'Remover',
    this.addButtonKey,
    this.removeButtonKey,
  });

  final TenantAdminImageUploadVariant variant;
  final Widget preview;
  final String? selectedLabel;
  final String addLabel;
  final String removeLabel;
  final Key? addButtonKey;
  final Key? removeButtonKey;
  final VoidCallback? onAdd;
  final VoidCallback? onRemove;
  final bool busy;
  final bool canRemove;

  bool get _isAvatar => variant == TenantAdminImageUploadVariant.avatar;

  @override
  Widget build(BuildContext context) {
    if (_isAvatar) {
      return Row(
        children: [
          preview,
          const SizedBox(width: 12),
          Expanded(
            child: _Details(
              selectedLabel: selectedLabel,
              busy: busy,
              addLabel: addLabel,
              removeLabel: removeLabel,
              addButtonKey: addButtonKey,
              removeButtonKey: removeButtonKey,
              onAdd: onAdd,
              onRemove: onRemove,
              canRemove: canRemove,
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        preview,
        const SizedBox(height: 8),
        _Details(
          selectedLabel: selectedLabel,
          busy: busy,
          addLabel: addLabel,
          removeLabel: removeLabel,
          addButtonKey: addButtonKey,
          removeButtonKey: removeButtonKey,
          onAdd: onAdd,
          onRemove: onRemove,
          canRemove: canRemove,
        ),
      ],
    );
  }
}

class _Details extends StatelessWidget {
  const _Details({
    required this.selectedLabel,
    required this.busy,
    required this.addLabel,
    required this.removeLabel,
    required this.addButtonKey,
    required this.removeButtonKey,
    required this.onAdd,
    required this.onRemove,
    required this.canRemove,
  });

  final String? selectedLabel;
  final bool busy;
  final String addLabel;
  final String removeLabel;
  final Key? addButtonKey;
  final Key? removeButtonKey;
  final VoidCallback? onAdd;
  final VoidCallback? onRemove;
  final bool canRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (selectedLabel != null) ...[
          Text(
            selectedLabel!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
        ],
        if (busy) ...[
          const LinearProgressIndicator(),
          const SizedBox(height: 8),
        ],
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.tonalIcon(
              key: addButtonKey,
              onPressed: busy ? null : onAdd,
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: Text(addLabel),
            ),
            if (canRemove)
              TextButton(
                key: removeButtonKey,
                onPressed: busy ? null : onRemove,
                child: Text(removeLabel),
              ),
          ],
        ),
      ],
    );
  }
}

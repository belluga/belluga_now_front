import 'package:flutter/material.dart';

class TenantAdminTokenChipsField extends StatefulWidget {
  const TenantAdminTokenChipsField({
    super.key,
    required this.label,
    required this.values,
    required this.onChanged,
    this.hintText = 'Adicionar item',
    this.emptyStateText = 'Nenhum item adicionado.',
    this.addButtonLabel = 'Adicionar',
  });

  final String label;
  final List<String> values;
  final ValueChanged<List<String>> onChanged;
  final String hintText;
  final String emptyStateText;
  final String addButtonLabel;

  @override
  State<TenantAdminTokenChipsField> createState() =>
      _TenantAdminTokenChipsFieldState();
}

class _TenantAdminTokenChipsFieldState extends State<TenantAdminTokenChipsField> {
  final TextEditingController _inputController = TextEditingController();

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  void _appendToken(String rawValue) {
    final candidate = rawValue.trim();
    if (candidate.isEmpty) {
      return;
    }
    final normalized = candidate.toLowerCase();
    final next = <String>[...widget.values];
    final exists = next.any((token) => token.toLowerCase() == normalized);
    if (!exists) {
      next.add(candidate);
      widget.onChanged(next);
    }
    _inputController.clear();
  }

  void _removeToken(String value) {
    final normalized = value.toLowerCase();
    final next = widget.values
        .where((token) => token.toLowerCase() != normalized)
        .toList(growable: false);
    widget.onChanged(next);
  }

  void _consumeInput() {
    final chunks = _inputController.text
        .split(RegExp(r'[,;\n]'))
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
    for (final chunk in chunks) {
      _appendToken(chunk);
    }
    _inputController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = widget.values;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        if (tokens.isEmpty)
          Text(
            widget.emptyStateText,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: tokens
                .map(
                  (token) => InputChip(
                    label: Text(token),
                    onDeleted: () => _removeToken(token),
                  ),
                )
                .toList(growable: false),
          ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _inputController,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  hintText: widget.hintText,
                ),
                onSubmitted: (_) => _consumeInput(),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.tonal(
              onPressed: _consumeInput,
              child: Text(widget.addButtonLabel),
            ),
          ],
        ),
      ],
    );
  }
}

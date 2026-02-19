import 'package:belluga_now/presentation/tenant_admin/shared/utils/tenant_admin_form_value_utils.dart';
import 'package:flutter/material.dart';

class TenantAdminHexColorField extends StatelessWidget {
  const TenantAdminHexColorField({
    super.key,
    required this.controller,
    required this.labelText,
    this.enabled = true,
    this.validator,
    this.suggestions = _defaultSuggestions,
    this.previewLabel,
  });

  final TextEditingController controller;
  final String labelText;
  final bool enabled;
  final String? Function(String?)? validator;
  final Map<String, Color> suggestions;
  final String? previewLabel;

  static const Map<String, Color> _defaultSuggestions = <String, Color>{
    '#E53935': Color(0xFFE53935),
    '#FB8C00': Color(0xFFFB8C00),
    '#43A047': Color(0xFF43A047),
    '#1E88E5': Color(0xFF1E88E5),
    '#8E24AA': Color(0xFF8E24AA),
    '#546E7A': Color(0xFF546E7A),
  };

  Color? _parseHexColor(String raw) {
    final trimmed = raw.trim();
    if (!RegExp(r'^#(?:[0-9a-fA-F]{6})$').hasMatch(trimmed)) {
      return null;
    }
    final hex = trimmed.substring(1);
    final colorValue = int.parse(hex, radix: 16);
    return Color(0xFF000000 | colorValue);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          enabled: enabled,
          decoration: InputDecoration(
            labelText: labelText,
          ),
          keyboardType: TextInputType.visiblePassword,
          textCapitalization: TextCapitalization.characters,
          autocorrect: false,
          enableSuggestions: false,
          validator: validator ?? tenantAdminValidateOptionalHexColor,
        ),
        const SizedBox(height: 8),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (context, colorValue, _) {
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: suggestions.entries
                  .map(
                    (entry) => ChoiceChip(
                      avatar: CircleAvatar(
                        radius: 7,
                        backgroundColor: entry.value,
                      ),
                      label: Text(entry.key),
                      selected: colorValue.text.toUpperCase() == entry.key,
                      onSelected: enabled
                          ? (_) {
                              controller.text = entry.key;
                            }
                          : null,
                    ),
                  )
                  .toList(growable: false),
            );
          },
        ),
        if (previewLabel != null) ...[
          const SizedBox(height: 8),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, colorValue, _) {
              final previewColor = _parseHexColor(colorValue.text);
              return Row(
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: previewColor ??
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    previewLabel!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              );
            },
          ),
        ],
      ],
    );
  }
}

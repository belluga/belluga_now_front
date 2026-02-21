import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class TenantAdminColorPickerField extends StatelessWidget {
  const TenantAdminColorPickerField({
    super.key,
    required this.controller,
    required this.labelText,
    this.enabled = true,
    this.pickerButtonKey,
    this.semanticsIdentifier,
    this.pickerButtonSemanticsIdentifier,
    this.fallbackColor,
  });

  final TextEditingController controller;
  final String labelText;
  final bool enabled;
  final Key? pickerButtonKey;
  final String? semanticsIdentifier;
  final String? pickerButtonSemanticsIdentifier;
  final Color? fallbackColor;

  static final RegExp _hexColorPattern = RegExp(r'^#(?:[0-9a-fA-F]{6})$');
  static const List<Color> _presetColors = [
    Color(0xFFE53935),
    Color(0xFFFB8C00),
    Color(0xFF43A047),
    Color(0xFF1E88E5),
    Color(0xFF8E24AA),
    Color(0xFF546E7A),
  ];

  String? _dialogPickerSemanticsIdentifier() {
    final id = semanticsIdentifier;
    if (id == null || id.isEmpty) {
      return null;
    }
    return '${id}_dialog_picker';
  }

  String? _dialogHexSemanticsIdentifier() {
    final id = semanticsIdentifier;
    if (id == null || id.isEmpty) {
      return null;
    }
    return '${id}_dialog_hex_value';
  }

  String? _dialogApplySemanticsIdentifier() {
    final id = semanticsIdentifier;
    if (id == null || id.isEmpty) {
      return null;
    }
    return '${id}_dialog_apply_button';
  }

  String? _dialogCancelSemanticsIdentifier() {
    final id = semanticsIdentifier;
    if (id == null || id.isEmpty) {
      return null;
    }
    return '${id}_dialog_cancel_button';
  }

  String? _dialogPresetSemanticsIdentifier(Color color) {
    final id = semanticsIdentifier;
    if (id == null || id.isEmpty) {
      return null;
    }
    final suffix = _toHex(color).replaceFirst('#', '').toLowerCase();
    return '${id}_dialog_preset_$suffix';
  }

  Color? _parseHexColor(String raw) {
    final trimmed = raw.trim();
    if (!_hexColorPattern.hasMatch(trimmed)) {
      return null;
    }
    final value = int.parse(trimmed.substring(1), radix: 16);
    return Color(0xFF000000 | value);
  }

  String _toHex(Color color) {
    final rgb = color.toARGB32() & 0x00FFFFFF;
    return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }

  Future<void> _openPicker(BuildContext context) async {
    if (!enabled) {
      return;
    }
    final theme = Theme.of(context);
    final baseColor = _parseHexColor(controller.text) ??
        fallbackColor ??
        theme.colorScheme.primary;
    var selected = baseColor;

    final picked = await showDialog<Color>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setState) {
            return AlertDialog(
              title: Text(labelText),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Semantics(
                      identifier: _dialogPickerSemanticsIdentifier(),
                      child: ColorPicker(
                        pickerColor: selected,
                        onColorChanged: (color) {
                          setState(() {
                            selected = Color(
                              0xFF000000 | (color.toARGB32() & 0x00FFFFFF),
                            );
                          });
                        },
                        enableAlpha: false,
                        displayThumbColor: true,
                        hexInputBar: false,
                        pickerAreaBorderRadius: const BorderRadius.all(
                          Radius.circular(12),
                        ),
                        portraitOnly: true,
                        labelTypes: const [],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Semantics(
                      identifier: _dialogHexSemanticsIdentifier(),
                      child: Text(
                        _toHex(selected),
                        style: Theme.of(dialogContext)
                            .textTheme
                            .labelLarge
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _presetColors.map((color) {
                        final isSelected = _toHex(color) == _toHex(selected);
                        return Semantics(
                          identifier: _dialogPresetSemanticsIdentifier(color),
                          button: true,
                          onTap: () => setState(() {
                            selected = color;
                          }),
                          child: FilterChip(
                            label: Text(_toHex(color)),
                            selected: isSelected,
                            avatar: CircleAvatar(
                              radius: 6,
                              backgroundColor: color,
                            ),
                            onSelected: (_) {
                              setState(() {
                                selected = color;
                              });
                            },
                          ),
                        );
                      }).toList(growable: false),
                    ),
                  ],
                ),
              ),
              actions: [
                Semantics(
                  identifier: _dialogCancelSemanticsIdentifier(),
                  button: true,
                  onTap: () => Navigator.of(dialogContext).pop(),
                  child: TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const Text('Cancelar'),
                  ),
                ),
                Semantics(
                  identifier: _dialogApplySemanticsIdentifier(),
                  button: true,
                  onTap: () => Navigator.of(dialogContext).pop(selected),
                  child: FilledButton(
                    onPressed: () => Navigator.of(dialogContext).pop(selected),
                    child: const Text('Aplicar cor'),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (picked == null) {
      return;
    }
    controller.text = _toHex(picked);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final scheme = Theme.of(context).colorScheme;
        final previewColor = _parseHexColor(value.text) ??
            fallbackColor ??
            scheme.surfaceContainerHighest;
        return Semantics(
          identifier: semanticsIdentifier,
          textField: true,
          onTap: enabled ? () => _openPicker(context) : null,
          child: TextFormField(
            controller: controller,
            readOnly: true,
            enabled: enabled,
            onTap: enabled ? () => _openPicker(context) : null,
            decoration: InputDecoration(
              labelText: labelText,
              prefixIcon: Padding(
                padding: const EdgeInsets.all(11),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: previewColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: scheme.outlineVariant),
                  ),
                ),
              ),
              suffixIcon: Semantics(
                identifier: pickerButtonSemanticsIdentifier,
                button: true,
                onTap: enabled ? () => _openPicker(context) : null,
                child: IconButton(
                  key: pickerButtonKey,
                  tooltip: 'Selecionar cor',
                  onPressed: enabled ? () => _openPicker(context) : null,
                  icon: const Icon(Icons.colorize_outlined),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

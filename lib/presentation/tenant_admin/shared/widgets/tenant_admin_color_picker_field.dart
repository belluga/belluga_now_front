import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter/services.dart';

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
    var hexInputErrorText = '';
    final hexController = TextEditingController(text: _toHex(baseColor));

    final picked = await showDialog<Color>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            final canApplySelectedColor =
                _parseHexColor(hexController.text.toUpperCase()) != null;

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
                          final normalized = Color(
                            0xFF000000 | (color.toARGB32() & 0x00FFFFFF),
                          );
                          selected = normalized;
                          hexInputErrorText = '';
                          hexController.value = TextEditingValue(
                            text: _toHex(normalized),
                            selection: TextSelection.collapsed(
                              offset: _toHex(normalized).length,
                            ),
                          );
                          setState(() {});
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
                      textField: true,
                      child: TextFormField(
                        controller: hexController,
                        keyboardType: TextInputType.visiblePassword,
                        textCapitalization: TextCapitalization.characters,
                        autocorrect: false,
                        enableSuggestions: false,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'[#0-9a-fA-F]'),
                          ),
                          LengthLimitingTextInputFormatter(7),
                        ],
                        decoration: InputDecoration(
                          labelText: 'Hex (#RRGGBB)',
                          helperText:
                              'Digite uma cor para sincronizar o picker',
                          errorText: hexInputErrorText.isEmpty
                              ? null
                              : hexInputErrorText,
                        ),
                        onChanged: (value) {
                          final uppercase = value.toUpperCase();
                          if (value != uppercase) {
                            hexController.value = TextEditingValue(
                              text: uppercase,
                              selection: TextSelection.collapsed(
                                offset: uppercase.length,
                              ),
                            );
                          }

                          final parsed = _parseHexColor(uppercase);
                          if (parsed == null) {
                            hexInputErrorText = uppercase.isEmpty
                                ? ''
                                : 'Formato inválido. Use #RRGGBB.';
                            setState(() {});
                            return;
                          }

                          selected = parsed;
                          hexInputErrorText = '';
                          setState(() {});
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                Semantics(
                  identifier: _dialogCancelSemanticsIdentifier(),
                  button: true,
                  onTap: () => dialogContext.router.pop(),
                  child: TextButton(
                    onPressed: () => dialogContext.router.pop(),
                    child: const Text('Cancelar'),
                  ),
                ),
                Semantics(
                  identifier: _dialogApplySemanticsIdentifier(),
                  button: true,
                  onTap: canApplySelectedColor
                      ? () => dialogContext.router.pop(selected)
                      : null,
                  child: FilledButton(
                    onPressed: canApplySelectedColor
                        ? () => dialogContext.router.pop(selected)
                        : null,
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

import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/domain/tenant_admin/settings/tenant_admin_map_filter_catalog_item.dart';
import 'package:belluga_now/domain/tenant_admin/settings/tenant_admin_map_filter_marker_override.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_flag_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_hex_color_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_optional_url_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_required_text_value.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_color_picker_field.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_map_marker_icon_picker_field.dart';
import 'package:flutter/material.dart';

Future<TenantAdminMapFilterCatalogItem?> showTenantAdminMapFilterVisualSheet({
  required BuildContext context,
  required TenantAdminMapFilterCatalogItem filter,
}) {
  return showModalBottomSheet<TenantAdminMapFilterCatalogItem>(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      return TenantAdminMapFilterVisualSheet(filter: filter);
    },
  );
}

class TenantAdminMapFilterVisualSheet extends StatefulWidget {
  const TenantAdminMapFilterVisualSheet({
    super.key,
    required this.filter,
  });

  final TenantAdminMapFilterCatalogItem filter;

  @override
  State<TenantAdminMapFilterVisualSheet> createState() =>
      _TenantAdminMapFilterVisualSheetState();
}

class _TenantAdminMapFilterVisualSheetState
    extends State<TenantAdminMapFilterVisualSheet> {
  late bool _overrideMarker;
  late TenantAdminMapFilterMarkerOverrideMode _markerMode;
  late TextEditingController _markerIconController;
  late TextEditingController _markerColorController;
  late TextEditingController _markerIconColorController;
  late TextEditingController _imageUriController;

  @override
  void initState() {
    super.initState();
    final markerOverride = widget.filter.markerOverride;
    _overrideMarker = widget.filter.overrideMarker;
    _markerMode =
        markerOverride?.mode ?? TenantAdminMapFilterMarkerOverrideMode.icon;
    _markerIconController = TextEditingController(
      text: markerOverride?.mode == TenantAdminMapFilterMarkerOverrideMode.icon
          ? (markerOverride?.icon ?? '')
          : '',
    );
    _markerColorController = TextEditingController(
      text: markerOverride?.mode == TenantAdminMapFilterMarkerOverrideMode.icon
          ? (markerOverride?.color ?? '#2563EB')
          : '#2563EB',
    );
    _markerIconColorController = TextEditingController(
      text: markerOverride?.mode == TenantAdminMapFilterMarkerOverrideMode.icon
          ? (markerOverride?.iconColor ?? '#FFFFFF')
          : '#FFFFFF',
    );
    _imageUriController = TextEditingController(
      text: widget.filter.imageUri ?? '',
    );
  }

  @override
  void dispose() {
    _markerIconController.dispose();
    _markerColorController.dispose();
    _markerIconColorController.dispose();
    _imageUriController.dispose();
    super.dispose();
  }

  String? _normalizeImageUri(String? raw) {
    final value = raw?.trim() ?? '';
    if (value.isEmpty) {
      return null;
    }
    return value;
  }

  String? _validateImageUri(String? raw) {
    final normalized = _normalizeImageUri(raw);
    if (normalized == null) {
      return null;
    }
    final uri = Uri.tryParse(normalized);
    if (uri == null ||
        (uri.scheme != 'http' && uri.scheme != 'https') ||
        uri.host.trim().isEmpty) {
      return 'Informe uma URL válida (http/https) para a imagem.';
    }
    return null;
  }

  String? _validateVisual() {
    final imageUriError = _validateImageUri(_imageUriController.text);
    if (imageUriError != null) {
      return imageUriError;
    }

    if (!_overrideMarker) {
      return null;
    }

    if (_markerMode == TenantAdminMapFilterMarkerOverrideMode.icon) {
      final icon = _markerIconController.text.trim();
      final color = _markerColorController.text.trim().toUpperCase();
      final iconColor = _markerIconColorController.text.trim().toUpperCase();
      if (icon.isEmpty ||
          !RegExp(r'^#[0-9A-F]{6}$').hasMatch(color) ||
          !RegExp(r'^#[0-9A-F]{6}$').hasMatch(iconColor)) {
        return 'Visual inválido: em modo ícone, informe ícone, cor do marcador e cor do ícone (#RRGGBB).';
      }
      return null;
    }

    final imageUri = _normalizeImageUri(_imageUriController.text);
    if (imageUri == null) {
      return 'Visual inválido: em modo imagem, defina a URL da imagem do filtro.';
    }
    return null;
  }

  TenantAdminMapFilterCatalogItem _buildResult() {
    final imageUri = _normalizeImageUri(_imageUriController.text);
    TenantAdminMapFilterMarkerOverride? nextMarkerOverride;
    if (_overrideMarker) {
      if (_markerMode == TenantAdminMapFilterMarkerOverrideMode.icon) {
        final iconValue = TenantAdminRequiredTextValue()
          ..parse(_markerIconController.text);
        final colorValue = TenantAdminHexColorValue()
          ..parse(_markerColorController.text);
        final iconColorValue = TenantAdminHexColorValue()
          ..parse(_markerIconColorController.text);
        nextMarkerOverride = TenantAdminMapFilterMarkerOverride.icon(
          iconValue: iconValue,
          colorValue: colorValue,
          iconColorValue: iconColorValue,
        );
      } else {
        final imageUriValue = TenantAdminOptionalUrlValue()
          ..parse(imageUri ?? '');
        nextMarkerOverride = TenantAdminMapFilterMarkerOverride.image(
          imageUriValue: imageUriValue,
        );
      }
    }

    final imageUriValue = imageUri == null
        ? null
        : (TenantAdminOptionalUrlValue()..parse(imageUri));
    return widget.filter.copyWith(
      imageUriValue: imageUriValue,
      clearImageUriValue: TenantAdminFlagValue(imageUri == null),
      overrideMarkerValue: TenantAdminFlagValue(_overrideMarker),
      markerOverride: nextMarkerOverride,
      clearMarkerOverrideValue: TenantAdminFlagValue(!_overrideMarker),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Visual do filtro',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              CheckboxListTile(
                value: _overrideMarker,
                contentPadding: EdgeInsets.zero,
                title: const Text('Sobrescrever marcador'),
                subtitle: const Text(
                  'Quando ativo, este filtro aplica o mesmo marcador em todos os POIs filtrados.',
                ),
                onChanged: (value) {
                  setState(() {
                    _overrideMarker = value ?? false;
                  });
                },
              ),
              if (_overrideMarker) ...[
                const SizedBox(height: 8),
                DropdownButtonFormField<TenantAdminMapFilterMarkerOverrideMode>(
                  initialValue: _markerMode,
                  decoration: const InputDecoration(
                    labelText: 'Modo do marcador',
                  ),
                  items: TenantAdminMapFilterMarkerOverrideMode.values
                      .map(
                        (mode) => DropdownMenuItem(
                          value: mode,
                          child: Text(mode.label),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }
                    setState(() {
                      _markerMode = value;
                    });
                  },
                ),
                if (_markerMode ==
                    TenantAdminMapFilterMarkerOverrideMode.icon) ...[
                  const SizedBox(height: 12),
                  TenantAdminMapMarkerIconPickerField(
                    controller: _markerIconController,
                    labelText: 'Ícone',
                  ),
                  const SizedBox(height: 12),
                  TenantAdminColorPickerField(
                    controller: _markerColorController,
                    labelText: 'Cor do marcador',
                  ),
                  const SizedBox(height: 12),
                  TenantAdminColorPickerField(
                    controller: _markerIconColorController,
                    labelText: 'Cor do ícone',
                  ),
                ],
                if (_markerMode ==
                    TenantAdminMapFilterMarkerOverrideMode.image) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _imageUriController,
                    decoration: const InputDecoration(
                      labelText: 'Imagem do marcador (URL)',
                      hintText: 'https://...',
                    ),
                    keyboardType: TextInputType.url,
                    textCapitalization: TextCapitalization.none,
                    autocorrect: false,
                    enableSuggestions: false,
                  ),
                ],
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  TextButton(
                    onPressed: () => context.router.maybePop(),
                    child: const Text('Cancelar'),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: () {
                      final validationError = _validateVisual();
                      if (validationError != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(validationError)),
                        );
                        return;
                      }
                      context.router.pop(_buildResult());
                    },
                    child: const Text('Aplicar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'dart:async';

import 'package:belluga_admin_ui/belluga_admin_ui.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_settings.dart';
import 'package:belluga_now/presentation/tenant_admin/settings/controllers/tenant_admin_settings_controller.dart';
import 'package:belluga_now/presentation/tenant_admin/settings/tenant_admin_settings_keys.dart';
import 'package:belluga_now/presentation/tenant_admin/settings/widgets/tenant_admin_settings_local_preferences_section.dart';
import 'package:belluga_now/presentation/tenant_admin/settings/widgets/tenant_admin_settings_remote_status_panel.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/utils/tenant_admin_image_ingestion_service.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_field_edit_sheet.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_image_crop_sheet.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_image_source_sheet.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_scoped_section_app_bar.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

class TenantAdminSettingsLocalPreferencesScreen extends StatefulWidget {
  const TenantAdminSettingsLocalPreferencesScreen({super.key});

  @override
  State<TenantAdminSettingsLocalPreferencesScreen> createState() =>
      _TenantAdminSettingsLocalPreferencesScreenState();
}

class _TenantAdminSettingsLocalPreferencesScreenState
    extends State<TenantAdminSettingsLocalPreferencesScreen> {
  final TenantAdminSettingsController _controller =
      GetIt.I.get<TenantAdminSettingsController>();
  final Map<String, bool> _mapFilterImageBusyByKey = <String, bool>{};

  @override
  void initState() {
    super.initState();
    _controller.bindLocalPreferencesFlow();
    unawaited(_initialize());
  }

  Future<void> _initialize() async {
    await _controller.init(loadBranding: false);
    await _controller.loadMapUiSettings();
  }

  void _handleBack() {
    if (context.router.canPop()) {
      context.router.pop();
      return;
    }
    context.router.replace(const TenantAdminSettingsRoute());
  }

  Future<void> _openDefaultOriginPicker() {
    return context.router.push(
      TenantAdminLocationPickerRoute(
        initialLocation: _controller.currentMapDefaultOriginLocation(),
      ),
    );
  }

  void _requestRebuild() {
    if (!mounted) {
      return;
    }
    (context as Element).markNeedsBuild();
  }

  bool _isMapFilterImageBusy(String filterKey) {
    final key = filterKey.trim().toLowerCase();
    return _mapFilterImageBusyByKey[key] ?? false;
  }

  void _setMapFilterImageBusy(String filterKey, bool value) {
    final key = filterKey.trim().toLowerCase();
    if (key.isEmpty || !mounted) {
      return;
    }
    _mapFilterImageBusyByKey[key] = value;
    _requestRebuild();
  }

  Future<void> _editMapFilterKey(int index) async {
    final settings = _controller.mapUiSettingsStreamValue.value;
    if (index < 0 || index >= settings.filters.length) {
      return;
    }
    final current = settings.filters[index];
    final result = await showTenantAdminFieldEditSheet(
      context: context,
      title: 'Editar chave do filtro',
      label: 'Chave',
      initialValue: current.key,
      confirmLabel: 'Salvar',
      validator: (value) {
        final trimmed = value?.trim() ?? '';
        if (trimmed.isEmpty) {
          return 'Informe a chave do filtro.';
        }
        return null;
      },
    );
    if (!mounted || result == null) {
      return;
    }
    _controller.updateMapFilterItemKey(index, result.value);
  }

  Future<void> _editMapFilterLabel(int index) async {
    final settings = _controller.mapUiSettingsStreamValue.value;
    if (index < 0 || index >= settings.filters.length) {
      return;
    }
    final current = settings.filters[index];
    final result = await showTenantAdminFieldEditSheet(
      context: context,
      title: 'Editar rótulo do filtro',
      label: 'Rótulo',
      initialValue: current.label,
      confirmLabel: 'Salvar',
      validator: (value) {
        final trimmed = value?.trim() ?? '';
        if (trimmed.isEmpty) {
          return 'Informe o rótulo do filtro.';
        }
        return null;
      },
    );
    if (!mounted || result == null) {
      return;
    }
    _controller.updateMapFilterItemLabel(index, result.value);
  }

  Future<void> _editMapFilterImage(int index) async {
    final settings = _controller.mapUiSettingsStreamValue.value;
    if (index < 0 || index >= settings.filters.length) {
      return;
    }
    final filter = settings.filters[index];
    if (_isMapFilterImageBusy(filter.key)) {
      return;
    }
    final source = await showTenantAdminImageSourceSheet(
      context: context,
      title: 'Selecionar imagem do filtro',
    );
    if (!mounted || source == null) {
      return;
    }
    if (source == TenantAdminImageSourceOption.device) {
      await _editMapFilterImageFromDevice(index, filter.key);
      return;
    }
    await _editMapFilterImageFromWeb(index, filter.key);
  }

  Future<void> _editMapFilterRule(int index) async {
    final settings = _controller.mapUiSettingsStreamValue.value;
    if (index < 0 || index >= settings.filters.length) {
      return;
    }
    await _controller.loadMapFilterRuleCatalog();
    if (!mounted) {
      return;
    }
    final catalog = _controller.mapFilterRuleCatalogStreamValue.value;
    if (catalog.isEmpty) {
      _controller.remoteErrorStreamValue.addValue(
        'Catálogo de tipos/taxonomias indisponível.',
      );
      return;
    }

    final filter = settings.filters[index];
    final result = await showModalBottomSheet<TenantAdminMapFilterQuery>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        var source = filter.query.source ?? TenantAdminMapFilterSource.event;
        var selectedTypes = Set<String>.from(filter.query.types);
        var selectedTaxonomy = Set<String>.from(filter.query.taxonomy);

        void sanitizeBySource() {
          final allowedTypes =
              catalog.typesForSource(source).map((item) => item.slug).toSet();
          selectedTypes = selectedTypes
              .where((entry) => allowedTypes.contains(entry))
              .toSet();
          final allowedTaxonomy = catalog
              .taxonomyForSource(source)
              .map((item) => item.token)
              .toSet();
          selectedTaxonomy = selectedTaxonomy
              .where((entry) => allowedTaxonomy.contains(entry))
              .toSet();
        }

        sanitizeBySource();

        return StatefulBuilder(
          builder: (context, setModalState) {
            final typeOptions = catalog.typesForSource(source);
            final taxonomyOptions = catalog.taxonomyForSource(source);
            final groupedTaxonomy =
                <String, List<TenantAdminMapFilterTaxonomyTermOption>>{};
            for (final option in taxonomyOptions) {
              groupedTaxonomy
                  .putIfAbsent(option.taxonomyLabel,
                      () => <TenantAdminMapFilterTaxonomyTermOption>[])
                  .add(option);
            }

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
                        'Regra do filtro',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<TenantAdminMapFilterSource>(
                        initialValue: source,
                        decoration: const InputDecoration(
                          labelText: 'Origem',
                        ),
                        items: TenantAdminMapFilterSource.values
                            .map(
                              (item) => DropdownMenuItem(
                                value: item,
                                child: Text(item.label),
                              ),
                            )
                            .toList(growable: false),
                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }
                          setModalState(() {
                            source = value;
                            sanitizeBySource();
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Tipos',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      if (typeOptions.isEmpty)
                        Text(
                          'Sem tipos para essa origem.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      if (typeOptions.isNotEmpty)
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: typeOptions.map((option) {
                            return FilterChip(
                              label: Text(option.label),
                              selected: selectedTypes.contains(option.slug),
                              onSelected: (selected) {
                                setModalState(() {
                                  if (selected) {
                                    selectedTypes.add(option.slug);
                                  } else {
                                    selectedTypes.remove(option.slug);
                                  }
                                });
                              },
                            );
                          }).toList(growable: false),
                        ),
                      const SizedBox(height: 16),
                      Text(
                        'Taxonomias',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      if (taxonomyOptions.isEmpty)
                        Text(
                          'Sem taxonomias para essa origem.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ...groupedTaxonomy.entries.map((entry) {
                        final options = entry.value;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                entry.key,
                                style: Theme.of(context).textTheme.labelLarge,
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: options.map((option) {
                                  return FilterChip(
                                    label: Text(option.label),
                                    selected:
                                        selectedTaxonomy.contains(option.token),
                                    onSelected: (selected) {
                                      setModalState(() {
                                        if (selected) {
                                          selectedTaxonomy.add(option.token);
                                        } else {
                                          selectedTaxonomy.remove(option.token);
                                        }
                                      });
                                    },
                                  );
                                }).toList(growable: false),
                              ),
                            ],
                          ),
                        );
                      }),
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
                              context.router.pop(
                                TenantAdminMapFilterQuery(
                                  source: source,
                                  types: selectedTypes.toList(growable: false),
                                  taxonomy:
                                      selectedTaxonomy.toList(growable: false),
                                ),
                              );
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
          },
        );
      },
    );

    if (result == null) {
      return;
    }
    _controller.updateMapFilterItemRule(index, result);
  }

  Future<void> _editMapFilterImageFromDevice(
    int index,
    String filterKey,
  ) async {
    _setMapFilterImageBusy(filterKey, true);
    try {
      final selected = await _controller.pickBrandingImageFromDevice(
        slot: TenantAdminImageSlot.mapFilter,
      );
      if (selected == null || !mounted) {
        return;
      }
      final cropped = await showTenantAdminImageCropSheet(
        context: context,
        sourceFile: selected,
        slot: TenantAdminImageSlot.mapFilter,
        readBytesForCrop: _controller.readImageBytesForCrop,
        prepareCroppedFile: (croppedData, cropSlot) =>
            _controller.prepareCroppedImage(
          croppedData,
          slot: cropSlot,
        ),
      );
      if (cropped == null) {
        return;
      }
      await _controller.uploadMapFilterItemImage(
        index: index,
        file: cropped,
      );
    } on TenantAdminImageIngestionException catch (error) {
      _controller.remoteErrorStreamValue.addValue(error.message);
    } catch (_) {
      _controller.remoteErrorStreamValue.addValue(
        'Nao foi possivel processar a imagem do filtro.',
      );
    } finally {
      _setMapFilterImageBusy(filterKey, false);
    }
  }

  Future<void> _editMapFilterImageFromWeb(
    int index,
    String filterKey,
  ) async {
    _setMapFilterImageBusy(filterKey, true);
    try {
      final result = await showTenantAdminFieldEditSheet(
        context: context,
        title: 'URL da imagem do filtro',
        label: 'URL',
        initialValue: '',
        confirmLabel: 'Baixar e recortar',
        keyboardType: TextInputType.url,
        textCapitalization: TextCapitalization.none,
        autocorrect: false,
        enableSuggestions: false,
        validator: (value) {
          final trimmed = value?.trim() ?? '';
          if (trimmed.isEmpty) {
            return 'Informe a URL da imagem.';
          }
          final uri = Uri.tryParse(trimmed);
          if (uri == null ||
              (uri.scheme != 'http' && uri.scheme != 'https') ||
              uri.host.trim().isEmpty) {
            return 'Informe uma URL valida (http/https).';
          }
          return null;
        },
      );
      if (!mounted || result == null) {
        return;
      }
      final sourceFile = await _controller.fetchBrandingImageFromUrlForCrop(
        imageUrl: result.value.trim(),
      );
      if (!mounted) {
        return;
      }
      final cropped = await showTenantAdminImageCropSheet(
        context: context,
        sourceFile: sourceFile,
        slot: TenantAdminImageSlot.mapFilter,
        readBytesForCrop: _controller.readImageBytesForCrop,
        prepareCroppedFile: (croppedData, cropSlot) =>
            _controller.prepareCroppedImage(
          croppedData,
          slot: cropSlot,
        ),
      );
      if (cropped == null) {
        return;
      }
      await _controller.uploadMapFilterItemImage(
        index: index,
        file: cropped,
      );
    } on TenantAdminImageIngestionException catch (error) {
      _controller.remoteErrorStreamValue.addValue(error.message);
    } catch (_) {
      _controller.remoteErrorStreamValue.addValue(
        'Nao foi possivel processar a imagem da web.',
      );
    } finally {
      _setMapFilterImageBusy(filterKey, false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: TenantAdminSettingsKeys.localPreferencesScreen,
      padding: const EdgeInsets.all(16),
      children: [
        TenantAdminScopedSectionAppBar(
          key: TenantAdminSettingsKeys.localPreferencesScopedAppBar,
          title: 'Preferências',
          backButtonKey: TenantAdminSettingsKeys.localPreferencesBackButton,
          onBack: _handleBack,
        ),
        const SizedBox(height: 12),
        TenantAdminSettingsSection(
          title: 'Ajustes locais',
          description: 'Tema local e alcance de mapa do operador admin.',
          icon: Icons.tune_rounded,
          child: TenantAdminSettingsLocalPreferencesSection(
            controller: _controller,
            onOpenDefaultOriginPicker: _openDefaultOriginPicker,
            onAddMapFilter: _controller.addMapFilterItem,
            onEditMapFilterKey: _editMapFilterKey,
            onEditMapFilterLabel: _editMapFilterLabel,
            onEditMapFilterRule: _editMapFilterRule,
            onEditMapFilterImage: _editMapFilterImage,
            onRemoveMapFilter: _controller.removeMapFilterItem,
            onMoveMapFilterUp: _controller.moveMapFilterItemUp,
            onMoveMapFilterDown: _controller.moveMapFilterItemDown,
            onClearMapFilterImage: _controller.clearMapFilterItemImage,
            isMapFilterImageBusy: _isMapFilterImageBusy,
          ),
        ),
        const SizedBox(height: 12),
        TenantAdminSettingsRemoteStatusPanel(
          controller: _controller,
          onReload: _controller.loadMapUiSettings,
        ),
      ],
    );
  }
}

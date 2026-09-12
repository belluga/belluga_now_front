import 'dart:async';

import 'package:belluga_now/application/router/support/tenant_admin_safe_back.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_home_favorites_pinned_profile_settings.dart';
import 'package:belluga_now/presentation/tenant_admin/settings/controllers/tenant_admin_home_favorites_pinned_profile_controller.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_account_profile_candidate_picker.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_scoped_section_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class TenantAdminHomeFavoritesPinnedProfileScreen extends StatefulWidget {
  const TenantAdminHomeFavoritesPinnedProfileScreen({super.key});

  @override
  State<TenantAdminHomeFavoritesPinnedProfileScreen> createState() =>
      _TenantAdminHomeFavoritesPinnedProfileScreenState();
}

class _TenantAdminHomeFavoritesPinnedProfileScreenState
    extends State<TenantAdminHomeFavoritesPinnedProfileScreen> {
  final _controller = GetIt.I
      .get<TenantAdminHomeFavoritesPinnedProfileController>();

  @override
  void initState() {
    super.initState();
    unawaited(_controller.init());
  }

  Future<void> _chooseProfile() async {
    final picker = _controller.createPickerSession();
    try {
      final selected = await showTenantAdminAccountProfileCandidatePicker(
        context: context,
        controller: picker,
        title: 'Selecionar perfil',
        emptyMessage: 'Nenhum perfil tenant-owned disponível.',
        closeOnSelection: true,
      );
      if (selected != null && selected.isNotEmpty) {
        _controller.select(selected.single);
      }
    } finally {
      _controller.disposePickerSession(picker);
    }
  }

  @override
  Widget build(BuildContext context) {
    final backPolicy = buildTenantAdminCurrentRouteBackPolicy(context);
    return ListView(
      key: const Key('tenant_admin_home_favorites_pin_screen'),
      padding: const EdgeInsets.all(16),
      children: [
        TenantAdminScopedSectionAppBar(
          title: 'Perfil em destaque',
          backButtonKey: const Key('tenant_admin_home_favorites_pin_back'),
          onBack: backPolicy.handleBack,
        ),
        const SizedBox(height: 16),
        StreamValueBuilder<TenantAdminHomeFavoritesPinnedProfileSettings>(
          streamValue: _controller.settingsStreamValue,
          onNullWidget: const Center(child: CircularProgressIndicator()),
          builder: (context, settings) {
            final selectedId = _controller.draftAccountProfileId;
            final selectedName = _controller.draftDisplayName;
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selectedName ??
                          (selectedId == null
                              ? 'Nenhum perfil selecionado'
                              : 'Perfil indisponível'),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (settings.isUnavailable) ...[
                      const SizedBox(height: 8),
                      Text(
                        'O perfil salvo não está mais disponível. A marca do tenant será exibida até uma nova seleção.',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilledButton.icon(
                          key: const Key(
                            'tenant_admin_home_favorites_pin_pick',
                          ),
                          onPressed: _chooseProfile,
                          icon: const Icon(Icons.person_search_outlined),
                          label: Text(
                            selectedId == null ? 'Selecionar' : 'Trocar',
                          ),
                        ),
                        if (selectedId != null)
                          OutlinedButton(
                            key: const Key(
                              'tenant_admin_home_favorites_pin_clear',
                            ),
                            onPressed: _controller.clear,
                            child: const Text('Remover'),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        StreamValueBuilder<TenantAdminHomeFavoritesPinnedProfileSettings>(
          streamValue: _controller.settingsStreamValue,
          onNullWidget: const FilledButton(
            key: Key('tenant_admin_home_favorites_pin_save'),
            onPressed: null,
            child: Text('Salvar'),
          ),
          builder: (context, _) => StreamValueBuilder<bool>(
            streamValue: _controller.isSavingStreamValue,
            builder: (context, isSaving) => FilledButton(
              key: const Key('tenant_admin_home_favorites_pin_save'),
              onPressed: isSaving ? null : _controller.save,
              child: Text(isSaving ? 'Salvando...' : 'Salvar'),
            ),
          ),
        ),
        StreamValueBuilder<String>(
          streamValue: _controller.errorStreamValue,
          onNullWidget: const SizedBox.shrink(),
          builder: (context, error) => Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  error,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
              if (!_controller.hasAuthoritativeBaseline)
                TextButton(
                  key: const Key('tenant_admin_home_favorites_pin_retry'),
                  onPressed: _controller.init,
                  child: const Text('Tentar novamente'),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

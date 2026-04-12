import 'dart:async';

import 'package:belluga_admin_ui/belluga_admin_ui.dart';
import 'package:belluga_now/application/router/support/tenant_admin_safe_back.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_settings.dart';
import 'package:belluga_now/presentation/tenant_admin/settings/controllers/tenant_admin_settings_controller.dart';
import 'package:belluga_now/presentation/tenant_admin/settings/tenant_admin_settings_keys.dart';
import 'package:belluga_now/presentation/tenant_admin/settings/widgets/tenant_admin_settings_remote_status_panel.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_confirmation_dialog.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_scoped_section_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class TenantAdminSettingsDomainsScreen extends StatefulWidget {
  const TenantAdminSettingsDomainsScreen({super.key});

  @override
  State<TenantAdminSettingsDomainsScreen> createState() =>
      _TenantAdminSettingsDomainsScreenState();
}

class _TenantAdminSettingsDomainsScreenState
    extends State<TenantAdminSettingsDomainsScreen> {
  final TenantAdminSettingsController _controller =
      GetIt.I.get<TenantAdminSettingsController>();

  @override
  void initState() {
    super.initState();
    unawaited(_initialize());
  }

  Future<void> _initialize() async {
    await _controller.init(loadBranding: false);
    await _controller.loadDomains();
  }

  Future<void> _handleCreateDomain() async {
    FocusManager.instance.primaryFocus?.unfocus();
    await _controller.createDomain();
  }

  Future<void> _handleDeleteDomain(TenantAdminDomainEntry domain) async {
    final confirmed = await showTenantAdminConfirmationDialog(
      context: context,
      title: 'Remover domínio?',
      message: 'O domínio "${domain.path}" será removido da lista ativa.',
      confirmLabel: 'Remover',
      isDestructive: true,
    );
    if (!mounted || !confirmed) {
      return;
    }
    await _controller.deleteDomain(domain);
  }

  Color _statusBackground(
    BuildContext context,
    TenantAdminDomainEntry domain,
  ) {
    final scheme = Theme.of(context).colorScheme;
    return scheme.secondaryContainer;
  }

  Color _statusForeground(
    BuildContext context,
    TenantAdminDomainEntry domain,
  ) {
    final scheme = Theme.of(context).colorScheme;
    return scheme.onSecondaryContainer;
  }

  String _statusLabel(TenantAdminDomainEntry domain) {
    return 'Ativo';
  }

  String _domainSummary(TenantAdminDomainEntry domain) {
    if (_controller.isCurrentTenantDomain(domain)) {
      return 'Domínio atual do admin';
    }
    return 'Domínio web ativo';
  }

  Widget _buildDomainCard(
    BuildContext context, {
    required TenantAdminDomainEntry domain,
    required int index,
    required bool isSubmitting,
  }) {
    final canDelete = _controller.canDeleteDomain(domain);

    return Card(
      key: TenantAdminSettingsKeys.domainsRow(index),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        domain.path,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _domainSummary(domain),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                Container(
                  key: TenantAdminSettingsKeys.domainsStatusChip(index),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _statusBackground(context, domain),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    _statusLabel(domain),
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: _statusForeground(context, domain),
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Tooltip(
                  message: canDelete
                      ? 'Remover domínio'
                      : 'Acesse outro domínio ativo para remover o domínio atual.',
                  child: OutlinedButton.icon(
                    key: TenantAdminSettingsKeys.domainsDeleteButton(index),
                    onPressed: isSubmitting || !canDelete
                        ? null
                        : () => _handleDeleteDomain(domain),
                    icon: const Icon(Icons.delete_outline),
                    label: Text(canDelete ? 'Remover' : 'Domínio atual'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final backPolicy = buildTenantAdminCurrentRouteBackPolicy(context);
    return ListView(
      key: TenantAdminSettingsKeys.domainsScreen,
      padding: const EdgeInsets.all(16),
      children: [
        TenantAdminScopedSectionAppBar(
          key: TenantAdminSettingsKeys.domainsScopedAppBar,
          title: 'Domínios',
          backButtonKey: TenantAdminSettingsKeys.domainsBackButton,
          onBack: backPolicy.handleBack,
        ),
        const SizedBox(height: 12),
        TenantAdminSettingsSection(
          title: 'Adicionar domínio',
          description:
              'Cadastre domínios web do tenant. O domínio atual não pode ser removido desta sessão.',
          icon: Icons.language_outlined,
          child: StreamValueBuilder<bool>(
            streamValue: _controller.domainsSubmittingStreamValue,
            builder: (context, isSubmitting) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    key: TenantAdminSettingsKeys.domainsPathField,
                    controller: _controller.domainPathController,
                    decoration: const InputDecoration(
                      labelText: 'Domínio web',
                      hintText: 'tenant.example.com',
                    ),
                    keyboardType: TextInputType.url,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _handleCreateDomain(),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    key: TenantAdminSettingsKeys.domainsAddButton,
                    onPressed: isSubmitting ? null : _handleCreateDomain,
                    icon: const Icon(Icons.add_link_outlined),
                    label: Text(
                      isSubmitting ? 'Salvando...' : 'Adicionar domínio',
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        TenantAdminSettingsSection(
          title: 'Domínios cadastrados',
          description:
              'A lista exibe apenas domínios web ativos disponíveis para esta operação.',
          icon: Icons.dns_outlined,
          child: StreamValueBuilder<List<TenantAdminDomainEntry>>(
            streamValue: _controller.domainsStreamValue,
            builder: (context, domains) {
              return StreamValueBuilder<bool>(
                streamValue: _controller.isRemoteLoadingStreamValue,
                builder: (context, isRemoteLoading) {
                  return StreamValueBuilder<bool>(
                    streamValue: _controller.domainsSubmittingStreamValue,
                    builder: (context, isSubmitting) {
                      return StreamValueBuilder<bool>(
                        streamValue: _controller.hasMoreDomainsStreamValue,
                        builder: (context, hasMore) {
                          return StreamValueBuilder<bool>(
                            streamValue:
                                _controller.domainsPageLoadingStreamValue,
                            builder: (context, isPageLoading) {
                              if (isRemoteLoading && domains.isEmpty) {
                                return const Center(
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(vertical: 24),
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              }

                              if (domains.isEmpty) {
                                return const Text(
                                  'Nenhum domínio cadastrado para este tenant.',
                                );
                              }

                              return Column(
                                children: [
                                  for (var index = 0;
                                      index < domains.length;
                                      index++) ...[
                                    if (index > 0) const SizedBox(height: 12),
                                    _buildDomainCard(
                                      context,
                                      domain: domains[index],
                                      index: index,
                                      isSubmitting: isSubmitting,
                                    ),
                                  ],
                                  if (hasMore || isPageLoading) ...[
                                    const SizedBox(height: 12),
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: OutlinedButton(
                                        key: TenantAdminSettingsKeys
                                            .domainsLoadMoreButton,
                                        onPressed: isPageLoading
                                            ? null
                                            : _controller.loadNextDomainsPage,
                                        child: Text(
                                          isPageLoading
                                              ? 'Carregando...'
                                              : 'Carregar mais',
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              );
                            },
                          );
                        },
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        TenantAdminSettingsRemoteStatusPanel(
          controller: _controller,
          onReload: _controller.loadDomains,
        ),
      ],
    );
  }
}

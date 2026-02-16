import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/presentation/common/widgets/belluga_network_image.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_profile_type.dart';
import 'package:belluga_now/presentation/tenant_admin/account_profiles/controllers/tenant_admin_account_profiles_controller.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_error_banner.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/utils/tenant_admin_form_value_utils.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_field_edit_sheet.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class TenantAdminAccountDetailScreen extends StatefulWidget {
  const TenantAdminAccountDetailScreen({
    super.key,
    required this.accountSlug,
  });

  final String accountSlug;

  @override
  State<TenantAdminAccountDetailScreen> createState() =>
      _TenantAdminAccountDetailScreenState();
}

class _TenantAdminAccountDetailScreenState
    extends State<TenantAdminAccountDetailScreen> {
  final TenantAdminAccountProfilesController _profilesController =
      GetIt.I.get<TenantAdminAccountProfilesController>();

  @override
  void initState() {
    super.initState();
    _profilesController.loadAccountDetail(_currentAccountSlugForRequests());
  }

  String _currentAccountSlugForRequests() {
    final current = _profilesController.accountStreamValue.value?.slug;
    if (current != null && current.isNotEmpty) {
      return current;
    }
    return widget.accountSlug;
  }

  String _profileTypeLabel(List<TenantAdminProfileTypeDefinition> types) {
    final profile = _profilesController.accountProfileStreamValue.value;
    if (profile == null) return '-';
    for (final type in types) {
      if (type.type == profile.profileType) {
        return type.label;
      }
    }
    return profile.profileType;
  }

  void _openCreate() {
    context.router
        .push(
          TenantAdminAccountProfileCreateRoute(
            accountSlug: _currentAccountSlugForRequests(),
          ),
        )
        .then((_) => _profilesController.loadAccountDetail(
              _currentAccountSlugForRequests(),
            ));
  }

  void _openEdit() {
    final profile = _profilesController.accountProfileStreamValue.value;
    if (profile == null) {
      return;
    }
    context.router
        .push(
          TenantAdminAccountProfileEditRoute(
            accountProfileId: profile.id,
          ),
        )
        .then((_) => _profilesController.loadAccountDetail(
              _currentAccountSlugForRequests(),
            ));
  }

  Future<void> _editAccountName(TenantAdminAccount account) async {
    final result = await showTenantAdminFieldEditSheet(
      context: context,
      title: 'Editar nome da conta',
      label: 'Nome',
      initialValue: account.name,
      helperText: 'Atualiza apenas o nome da conta.',
      textCapitalization: TextCapitalization.words,
      textInputAction: TextInputAction.done,
      autocorrect: true,
      enableSuggestions: true,
      validator: (value) {
        final trimmed = value?.trim() ?? '';
        if (trimmed.isEmpty) {
          return 'Nome e obrigatorio.';
        }
        return null;
      },
    );
    if (result == null || !mounted) {
      return;
    }
    final trimmed = result.value.trim();
    if (trimmed.isEmpty || trimmed == account.name) {
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    final updated = await _profilesController.updateAccount(
      accountSlug: _currentAccountSlugForRequests(),
      name: trimmed,
    );
    if (!mounted || updated == null) {
      return;
    }
    messenger.showSnackBar(
      const SnackBar(content: Text('Nome da conta atualizado.')),
    );
  }

  Future<void> _editAccountSlug(TenantAdminAccount account) async {
    final result = await showTenantAdminFieldEditSheet(
      context: context,
      title: 'Editar slug da conta',
      label: 'Slug',
      initialValue: account.slug,
      helperText: 'Deve ser unico no tenant.',
      textInputAction: TextInputAction.done,
      inputFormatters: tenantAdminSlugInputFormatters,
      validator: (value) => tenantAdminValidateRequiredSlug(
        value,
        requiredMessage: 'Slug e obrigatorio.',
      ),
    );
    if (result == null || !mounted) {
      return;
    }
    final trimmed = result.value.trim();
    if (trimmed.isEmpty || trimmed == account.slug) {
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    final updated = await _profilesController.updateAccount(
      accountSlug: _currentAccountSlugForRequests(),
      slug: trimmed,
    );
    if (!mounted || updated == null) {
      return;
    }
    messenger.showSnackBar(
      const SnackBar(content: Text('Slug da conta atualizado.')),
    );
  }

  @override
  void dispose() {
    _profilesController.resetAccountDetail();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamValueBuilder<bool>(
      streamValue: _profilesController.accountDetailLoadingStreamValue,
      builder: (context, isLoading) {
        return StreamValueBuilder<String?>(
          streamValue: _profilesController.accountDetailErrorStreamValue,
          builder: (context, errorMessage) {
            return StreamValueBuilder<TenantAdminAccount?>(
              streamValue: _profilesController.accountStreamValue,
              builder: (context, account) {
                return StreamValueBuilder<TenantAdminAccountProfile?>(
                  streamValue: _profilesController.accountProfileStreamValue,
                  builder: (context, profile) {
                    final coverUrl = profile?.coverUrl;
                    final avatarUrl = profile?.avatarUrl;
                    final location = profile?.location;
                    final accountSlugForUi =
                        account?.slug ?? _currentAccountSlugForRequests();

                    return Scaffold(
                      appBar: AppBar(
                        title: Text('Conta: $accountSlugForUi'),
                        actions: [
                          if (profile != null)
                            FilledButton.tonalIcon(
                              onPressed: isLoading ? null : _openEdit,
                              icon: const Icon(Icons.edit_outlined),
                              label: const Text('Editar'),
                            ),
                        ],
                      ),
                      body: Padding(
                        padding: const EdgeInsets.all(16),
                        child: isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : errorMessage != null
                                ? TenantAdminErrorBanner(
                                    rawError: errorMessage,
                                    fallbackMessage:
                                        'Não foi possível carregar os dados da conta.',
                                    onRetry: () =>
                                        _profilesController.loadAccountDetail(
                                      _currentAccountSlugForRequests(),
                                    ),
                                  )
                                : StreamValueBuilder(
                                    streamValue: _profilesController
                                        .profileTypesStreamValue,
                                    builder: (context, types) {
                                      return ListView(
                                        children: [
                                          Card(
                                            margin: EdgeInsets.zero,
                                            child: Padding(
                                              padding: const EdgeInsets.all(16),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Detalhes da conta',
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .titleMedium,
                                                  ),
                                                  const SizedBox(height: 12),
                                                  _buildEditableRow(
                                                    label: 'Slug',
                                                    value: account?.slug ?? '-',
                                                    onEdit: account == null
                                                        ? null
                                                        : () =>
                                                            _editAccountSlug(
                                                              account,
                                                            ),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  _buildEditableRow(
                                                    label: 'Nome',
                                                    value: account?.name ?? '-',
                                                    onEdit: account == null
                                                        ? null
                                                        : () =>
                                                            _editAccountName(
                                                              account,
                                                            ),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  _buildRow(
                                                    'Documento',
                                                    account?.document.number ??
                                                        '-',
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          if (profile == null) ...[
                                            Card(
                                              margin: EdgeInsets.zero,
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.all(16),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      'Perfil da conta',
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .titleMedium,
                                                    ),
                                                    const SizedBox(height: 8),
                                                    const Text(
                                                      'Nenhum perfil associado a esta conta.',
                                                    ),
                                                    const SizedBox(height: 12),
                                                    FilledButton(
                                                      onPressed: _openCreate,
                                                      child: const Text(
                                                          'Criar Perfil'),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ] else ...[
                                            Card(
                                              margin: EdgeInsets.zero,
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.all(16),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      'Perfil da conta',
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .titleMedium,
                                                    ),
                                                    const SizedBox(height: 12),
                                                    if (coverUrl != null &&
                                                        coverUrl.isNotEmpty)
                                                      BellugaNetworkImage(
                                                        coverUrl,
                                                        height: 160,
                                                        fit: BoxFit.cover,
                                                        clipBorderRadius:
                                                            BorderRadius
                                                                .circular(12),
                                                        errorWidget: Container(
                                                          height: 160,
                                                          decoration:
                                                              BoxDecoration(
                                                            color: Theme.of(
                                                                    context)
                                                                .colorScheme
                                                                .surfaceContainerHighest,
                                                          ),
                                                          child: const Center(
                                                            child: Icon(
                                                              Icons
                                                                  .image_not_supported,
                                                            ),
                                                          ),
                                                        ),
                                                      )
                                                    else
                                                      Container(
                                                        height: 160,
                                                        decoration:
                                                            BoxDecoration(
                                                          color: Theme.of(
                                                                  context)
                                                              .colorScheme
                                                              .surfaceContainerHighest,
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(12),
                                                        ),
                                                        child: const Center(
                                                          child: Icon(Icons
                                                              .image_outlined),
                                                        ),
                                                      ),
                                                    const SizedBox(height: 16),
                                                    Row(
                                                      children: [
                                                        if (avatarUrl != null &&
                                                            avatarUrl
                                                                .isNotEmpty)
                                                          BellugaNetworkImage(
                                                            avatarUrl,
                                                            width: 72,
                                                            height: 72,
                                                            fit: BoxFit.cover,
                                                            clipBorderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        36),
                                                            errorWidget:
                                                                Container(
                                                              width: 72,
                                                              height: 72,
                                                              decoration:
                                                                  BoxDecoration(
                                                                color: Theme.of(
                                                                        context)
                                                                    .colorScheme
                                                                    .surfaceContainerHighest,
                                                              ),
                                                              child: const Icon(
                                                                Icons
                                                                    .person_off_outlined,
                                                              ),
                                                            ),
                                                          )
                                                        else
                                                          Container(
                                                            width: 72,
                                                            height: 72,
                                                            decoration:
                                                                BoxDecoration(
                                                              color: Theme.of(
                                                                      context)
                                                                  .colorScheme
                                                                  .surfaceContainerHighest,
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          36),
                                                            ),
                                                            child: const Icon(
                                                              Icons
                                                                  .person_outline,
                                                            ),
                                                          ),
                                                        const SizedBox(
                                                            width: 12),
                                                        Expanded(
                                                          child: Text(
                                                            profile.displayName,
                                                            style: Theme.of(
                                                                    context)
                                                                .textTheme
                                                                .titleMedium,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 16),
                                                    _buildRow(
                                                        'Tipo',
                                                        _profileTypeLabel(
                                                            types)),
                                                    const SizedBox(height: 8),
                                                    if (location != null)
                                                      _buildRow(
                                                        'Localização',
                                                        '${location.latitude.toStringAsFixed(6)}, '
                                                            '${location.longitude.toStringAsFixed(6)}',
                                                      ),
                                                    if (profile.bio != null &&
                                                        profile.bio!
                                                            .trim()
                                                            .isNotEmpty) ...[
                                                      const SizedBox(height: 8),
                                                      _buildRow(
                                                        'Bio',
                                                        _stripHtml(
                                                          profile.bio!.trim(),
                                                        ),
                                                      ),
                                                    ],
                                                    if (profile.content !=
                                                            null &&
                                                        profile.content!
                                                            .trim()
                                                            .isNotEmpty) ...[
                                                      const SizedBox(height: 8),
                                                      _buildRow(
                                                        'Conteúdo',
                                                        _stripHtml(
                                                          profile.content!
                                                              .trim(),
                                                        ),
                                                      ),
                                                    ],
                                                    const SizedBox(height: 12),
                                                    Align(
                                                      alignment:
                                                          Alignment.centerRight,
                                                      child:
                                                          OutlinedButton.icon(
                                                        onPressed: _openEdit,
                                                        icon: const Icon(Icons
                                                            .edit_outlined),
                                                        label: const Text(
                                                            'Editar Perfil'),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      );
                                    },
                                  ),
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(child: Text(value)),
      ],
    );
  }

  Widget _buildEditableRow({
    required String label,
    required String value,
    required VoidCallback? onEdit,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(child: Text(value)),
        IconButton(
          onPressed: onEdit,
          tooltip: 'Editar $label',
          icon: const Icon(Icons.edit_outlined),
        ),
      ],
    );
  }

  String _stripHtml(String value) {
    return value
        .replaceAll(RegExp(r'<[^>]+>'), ' ')
        .replaceAll('&nbsp;', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}

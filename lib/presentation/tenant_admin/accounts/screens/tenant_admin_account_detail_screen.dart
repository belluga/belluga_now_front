import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/rich_text/safe_rich_html.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/application/router/support/tenant_admin_safe_back.dart';
import 'package:belluga_now/domain/tenant_admin/ownership_state.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_profile_type.dart';
import 'package:belluga_now/presentation/tenant_admin/accounts/controllers/tenant_admin_account_detail_controller.dart';
import 'package:belluga_now/presentation/shared/widgets/belluga_network_image.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_error_banner.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/utils/tenant_admin_form_value_utils.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_field_edit_sheet.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart' hide Marker;
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
  final TenantAdminAccountDetailController _profilesController =
      GetIt.I.get<TenantAdminAccountDetailController>();
  bool _routeParamNormalized = false;

  @override
  void initState() {
    super.initState();
    _profilesController.loadAccountDetail(_currentAccountSlugForRequests());
  }

  String _currentAccountSlugForRequests() {
    final current = _profilesController.accountStreamValue.value?.slug;
    if (_isResolvedSlug(current)) {
      return current!.trim();
    }
    return widget.accountSlug;
  }

  bool _isResolvedSlug(String? value) {
    if (value == null) {
      return false;
    }
    final trimmed = value.trim();
    return trimmed.isNotEmpty && !trimmed.startsWith(':');
  }

  bool _requiresPathNormalization() {
    return kIsWeb && context.router.currentPath.contains('/:');
  }

  void _normalizeRouteParamIfNeeded(TenantAdminAccount? account) {
    if (_routeParamNormalized || !mounted) {
      return;
    }
    final incoming = widget.accountSlug;
    final resolved = account?.slug;
    final needsPathNormalization = _requiresPathNormalization();
    if (!needsPathNormalization && _isResolvedSlug(incoming)) {
      _routeParamNormalized = true;
      return;
    }
    final resolvedSlug = _isResolvedSlug(incoming) ? incoming : resolved;
    if (!_isResolvedSlug(resolvedSlug)) {
      return;
    }
    _routeParamNormalized = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      context.router.replace(
        TenantAdminAccountDetailRoute(accountSlug: resolvedSlug!.trim()),
      );
    });
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

  void _openEdit() {
    final profile = _profilesController.accountProfileStreamValue.value;
    if (profile == null) {
      return;
    }
    context.router
        .push(
      TenantAdminAccountProfileEditRoute(
        accountSlug: _currentAccountSlugForRequests(),
        accountProfileId: profile.id,
      ),
    )
        .then((_) {
      if (!mounted) {
        return;
      }
      unawaited(
        _profilesController.loadAccountDetail(_currentAccountSlugForRequests()),
      );
    });
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

  Future<void> _confirmDeleteAccount(TenantAdminAccount account) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Excluir conta'),
          content: Text(
            'Deseja excluir a conta "${account.name}"? Esta acao remove tambem o perfil associado.',
          ),
          actions: [
            TextButton(
              onPressed: () => dialogContext.router.maybePop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton.tonal(
              onPressed: () => dialogContext.router.maybePop(true),
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) {
      return;
    }
    final deleted = await _profilesController.deleteAccount(
      accountSlug: account.slug,
    );
    if (!mounted) {
      return;
    }
    if (!deleted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nao foi possivel excluir a conta.')),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Conta excluida com sucesso.')),
    );
  }

  bool _canDeleteAccount(TenantAdminAccount? account) {
    if (account == null) {
      return false;
    }
    return account.ownershipState == TenantAdminOwnershipState.unmanaged;
  }

  @override
  void dispose() {
    _profilesController.resetAccountDetail();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final backPolicy = buildTenantAdminCurrentRouteBackPolicy(context);
    return StreamValueBuilder<bool>(
      streamValue: _profilesController.accountDeletingStreamValue,
      builder: (context, isDeleting) {
        return StreamValueBuilder<bool>(
          streamValue: _profilesController.accountDetailLoadingStreamValue,
          builder: (context, isLoading) {
            return StreamValueBuilder<String?>(
              streamValue: _profilesController.accountDetailErrorStreamValue,
              builder: (context, errorMessage) {
                return StreamValueBuilder<TenantAdminAccount?>(
                  streamValue: _profilesController.accountStreamValue,
                  builder: (context, account) {
                    _normalizeRouteParamIfNeeded(account);
                    return StreamValueBuilder<TenantAdminAccountProfile?>(
                      streamValue:
                          _profilesController.accountProfileStreamValue,
                      builder: (context, profile) {
                        final coverUrl = profile?.coverUrl;
                        final avatarUrl = profile?.avatarUrl;
                        final location = profile?.location;
                        final accountSlugForUi =
                            account?.slug ?? _currentAccountSlugForRequests();

                        return Scaffold(
                          appBar: AppBar(
                            leading: IconButton(
                              tooltip: 'Voltar',
                              onPressed: backPolicy.handleBack,
                              icon: const Icon(Icons.arrow_back_rounded),
                            ),
                            title: Text('Conta: $accountSlugForUi'),
                            actions: [
                              if (profile case final _?)
                                FilledButton.tonalIcon(
                                  onPressed: (isLoading || isDeleting)
                                      ? null
                                      : _openEdit,
                                  icon: const Icon(Icons.edit_outlined),
                                  label: const Text('Editar'),
                                ),
                            ],
                          ),
                          body: Padding(
                            padding: const EdgeInsets.all(16),
                            child: isLoading
                                ? const Center(
                                    child: CircularProgressIndicator(),
                                  )
                                : (errorMessage?.isNotEmpty ?? false)
                                    ? TenantAdminErrorBanner(
                                        rawError: errorMessage ?? '',
                                        fallbackMessage:
                                            'Não foi possível carregar os dados da conta.',
                                        onRetry: () => _profilesController
                                            .loadAccountDetail(
                                          _currentAccountSlugForRequests(),
                                        ),
                                      )
                                    : StreamValueBuilder<
                                        List<TenantAdminProfileTypeDefinition>>(
                                        streamValue: _profilesController
                                            .profileTypesStreamValue,
                                        builder: (context, types) {
                                          return ListView(
                                            children: [
                                              Card(
                                                margin: EdgeInsets.zero,
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.all(16),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        'Detalhes da conta',
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .titleMedium,
                                                      ),
                                                      const SizedBox(
                                                          height: 12),
                                                      _buildEditableRow(
                                                        label: 'Slug',
                                                        value: account?.slug ??
                                                            '-',
                                                        onEdit: switch (
                                                            account) {
                                                          final value? => () =>
                                                              _editAccountSlug(
                                                                value,
                                                              ),
                                                          null => null,
                                                        },
                                                      ),
                                                      const SizedBox(height: 8),
                                                      _buildEditableRow(
                                                        label: 'Nome',
                                                        value: account?.name ??
                                                            '-',
                                                        onEdit: switch (
                                                            account) {
                                                          final value? => () =>
                                                              _editAccountName(
                                                                value,
                                                              ),
                                                          null => null,
                                                        },
                                                      ),
                                                      const SizedBox(height: 8),
                                                      _buildRow(
                                                        'Documento',
                                                        account?.document
                                                                .number ??
                                                            '-',
                                                      ),
                                                      const SizedBox(height: 8),
                                                      _buildRow(
                                                        'Segmentacao',
                                                        account?.ownershipState
                                                                .label ??
                                                            '-',
                                                      ),
                                                      if (_canDeleteAccount(
                                                        account,
                                                      )) ...[
                                                        const SizedBox(
                                                            height: 12),
                                                        Align(
                                                          alignment: Alignment
                                                              .centerRight,
                                                          child:
                                                              TextButton.icon(
                                                            onPressed: isDeleting ||
                                                                    account
                                                                        is! TenantAdminAccount
                                                                ? null
                                                                : () =>
                                                                    _confirmDeleteAccount(
                                                                      account,
                                                                    ),
                                                            icon: const Icon(
                                                              Icons
                                                                  .delete_outline,
                                                            ),
                                                            label: const Text(
                                                              'Excluir conta',
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 16),
                                              if (profile
                                                  is! TenantAdminAccountProfile) ...[
                                                Card(
                                                  margin: EdgeInsets.zero,
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            16),
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          'Inconsistência de dados',
                                                          style:
                                                              Theme.of(context)
                                                                  .textTheme
                                                                  .titleMedium,
                                                        ),
                                                        const SizedBox(
                                                            height: 8),
                                                        const Text(
                                                          'Conta sem perfil detectada. Este estado é inválido para tenant-admin e deve ser corrigido por rotina de reparo backend.',
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
                                                        const EdgeInsets.all(
                                                            16),
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          'Perfil da conta',
                                                          style:
                                                              Theme.of(context)
                                                                  .textTheme
                                                                  .titleMedium,
                                                        ),
                                                        const SizedBox(
                                                            height: 12),
                                                        if (coverUrl != null &&
                                                            coverUrl.isNotEmpty)
                                                          BellugaNetworkImage(
                                                            coverUrl,
                                                            height: 160,
                                                            fit: BoxFit.cover,
                                                            clipBorderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        12),
                                                            errorWidget:
                                                                Container(
                                                              height: 160,
                                                              decoration:
                                                                  BoxDecoration(
                                                                color: Theme.of(
                                                                        context)
                                                                    .colorScheme
                                                                    .surfaceContainerHighest,
                                                              ),
                                                              child:
                                                                  const Center(
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
                                                                      .circular(
                                                                          12),
                                                            ),
                                                            child: const Center(
                                                              child: Icon(
                                                                Icons
                                                                    .image_outlined,
                                                              ),
                                                            ),
                                                          ),
                                                        const SizedBox(
                                                            height: 16),
                                                        Row(
                                                          children: [
                                                            if (avatarUrl !=
                                                                    null &&
                                                                avatarUrl
                                                                    .isNotEmpty)
                                                              BellugaNetworkImage(
                                                                avatarUrl,
                                                                width: 72,
                                                                height: 72,
                                                                fit: BoxFit
                                                                    .cover,
                                                                clipBorderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                  36,
                                                                ),
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
                                                                  child:
                                                                      const Icon(
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
                                                                    36,
                                                                  ),
                                                                ),
                                                                child:
                                                                    const Icon(
                                                                  Icons
                                                                      .person_outline,
                                                                ),
                                                              ),
                                                            const SizedBox(
                                                              width: 12,
                                                            ),
                                                            Expanded(
                                                              child: Text(
                                                                profile
                                                                    .displayName,
                                                                style: Theme.of(
                                                                        context)
                                                                    .textTheme
                                                                    .titleMedium,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                        const SizedBox(
                                                            height: 16),
                                                        _buildRow(
                                                          'Tipo',
                                                          _profileTypeLabel(
                                                              types),
                                                        ),
                                                        const SizedBox(
                                                            height: 8),
                                                        if (location != null)
                                                          _buildRow(
                                                            'Localização',
                                                            '${location.latitude.toStringAsFixed(6)}, '
                                                                '${location.longitude.toStringAsFixed(6)}',
                                                          ),
                                                        if (profile.bio !=
                                                                null &&
                                                            profile.bio!
                                                                .trim()
                                                                .isNotEmpty) ...[
                                                          const SizedBox(
                                                              height: 8),
                                                          _buildRichTextRow(
                                                            'Bio',
                                                            profile.bio!.trim(),
                                                          ),
                                                        ],
                                                        if (profile.content !=
                                                                null &&
                                                            profile.content!
                                                                .trim()
                                                                .isNotEmpty) ...[
                                                          const SizedBox(
                                                              height: 8),
                                                          _buildRichTextRow(
                                                            'Conteúdo',
                                                            profile.content!
                                                                .trim(),
                                                          ),
                                                        ],
                                                        const SizedBox(
                                                            height: 12),
                                                        Align(
                                                          alignment: Alignment
                                                              .centerRight,
                                                          child: OutlinedButton
                                                              .icon(
                                                            onPressed:
                                                                isDeleting
                                                                    ? null
                                                                    : _openEdit,
                                                            icon: const Icon(
                                                              Icons
                                                                  .edit_outlined,
                                                            ),
                                                            label: const Text(
                                                              'Editar Perfil',
                                                            ),
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

  Widget _buildRichTextRow(String label, String value) {
    final html = SafeRichHtml.canonicalize(value);
    if (html.isEmpty) {
      return const SizedBox.shrink();
    }
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
        Expanded(
          child: SafeRichHtml.looksLikeHtml(value)
              ? _richHtmlPreview(html)
              : _plainRichTextPreview(value),
        ),
      ],
    );
  }

  Widget _richHtmlPreview(String html) {
    final colorScheme = Theme.of(context).colorScheme;
    return Html(
      data: html,
      style: {
        'body': Style(
          margin: Margins.zero,
          padding: HtmlPaddings.zero,
          color: colorScheme.onSurface,
          fontSize: FontSize(
            Theme.of(context).textTheme.bodyMedium?.fontSize ?? 14,
          ),
          lineHeight: const LineHeight(1.35),
        ),
        'p': Style(
          margin: Margins.only(bottom: 8),
        ),
        'strong': Style(
          fontWeight: FontWeight.w800,
        ),
        'br': Style(
          display: Display.block,
        ),
      },
    );
  }

  Widget _plainRichTextPreview(String value) {
    final normalized =
        value.replaceAll('\r\n', '\n').replaceAll('\r', '\n').trim();
    final paragraphs = normalized
        .split(RegExp(r'\n\s*\n+'))
        .where((paragraph) => paragraph.trim().isNotEmpty)
        .toList(growable: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var paragraphIndex = 0;
            paragraphIndex < paragraphs.length;
            paragraphIndex++) ...[
          if (paragraphIndex > 0) const SizedBox(height: 8),
          for (final line in paragraphs[paragraphIndex].split('\n'))
            if (line.trim().isNotEmpty)
              Text(
                line.trimRight(),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      height: 1.35,
                    ),
              ),
        ],
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
}

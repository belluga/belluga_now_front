import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/icons/account_profile_external_link_icon_registry.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/domain/partners/account_profile_external_link.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile.dart';
import 'package:belluga_now/presentation/tenant_admin/account_profiles/controllers/tenant_admin_account_profiles_controller.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_confirmation_dialog.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class TenantAdminAccountProfileExternalLinkFormScreen extends StatefulWidget {
  const TenantAdminAccountProfileExternalLinkFormScreen({
    super.key,
    required this.accountSlug,
    required this.accountProfile,
    required this.draft,
  });

  final String accountSlug;
  final TenantAdminAccountProfile accountProfile;
  final TenantAdminAccountProfileExternalLinkDraft draft;

  @override
  State<TenantAdminAccountProfileExternalLinkFormScreen> createState() =>
      _TenantAdminAccountProfileExternalLinkFormScreenState();
}

class _TenantAdminAccountProfileExternalLinkFormScreenState
    extends State<TenantAdminAccountProfileExternalLinkFormScreen> {
  final TenantAdminAccountProfilesController _controller = GetIt.I
      .get<TenantAdminAccountProfilesController>();
  bool _discardDialogVisible = false;
  bool _returnedToParent = false;

  @override
  void dispose() {
    _controller.endExternalLinkDraft(widget.draft);
    super.dispose();
  }

  void _replaceWithParent() {
    if (!mounted || _returnedToParent) return;
    _returnedToParent = true;
    unawaited(
      context.router.replace(
        TenantAdminAccountProfileEditRoute(
          accountSlug: widget.accountSlug,
          accountProfileId: widget.accountProfile.id,
        ),
      ),
    );
  }

  Future<void> _confirmDiscardAndExit(
    TenantAdminAccountProfileExternalLinkDraft draft,
  ) async {
    if (_discardDialogVisible) return;
    _discardDialogVisible = true;
    final discard = await showTenantAdminConfirmationDialog(
      context: context,
      title: 'Sair sem salvar?',
      message: 'As alterações neste link ainda não foram salvas.',
      confirmLabel: 'Sair sem salvar',
      cancelLabel: 'Continuar editando',
      isDestructive: true,
    );
    _discardDialogVisible = false;
    if (!mounted || !discard) return;
    draft.acceptDiscard();
    _replaceWithParent();
  }

  List<AccountProfileExternalLinkType> _availableTypes(
    TenantAdminAccountProfileExternalLinkDraft draft,
  ) {
    final configuredTypes = widget.accountProfile.externalLinks
        .map((link) => link.type)
        .toSet();
    return AccountProfileExternalLinkType.values
        .where(
          (type) => draft.isEditing
              ? type == draft.selectedTypeStreamValue.value
              : !configuredTypes.contains(type),
        )
        .toList(growable: false);
  }

  Future<void> _save(TenantAdminAccountProfileExternalLinkDraft draft) async {
    final outcome = await _controller.saveExternalLinkDraft(draft);
    if (!mounted) return;
    if (outcome == TenantAdminExternalLinkMutationOutcome.saved ||
        outcome == TenantAdminExternalLinkMutationOutcome.capabilityDisabled) {
      _replaceWithParent();
    }
  }

  Future<void> _delete(TenantAdminAccountProfileExternalLinkDraft draft) async {
    final confirmed = await showTenantAdminConfirmationDialog(
      context: context,
      title: 'Remover link externo?',
      message: 'Esta ação remove o atalho deste perfil.',
      confirmLabel: 'Remover',
      cancelLabel: 'Cancelar',
      isDestructive: true,
    );
    if (!confirmed || !mounted) return;
    final outcome = await _controller.deleteExternalLinkDraft(draft);
    if (!mounted) return;
    if (outcome == TenantAdminExternalLinkMutationOutcome.deleted ||
        outcome == TenantAdminExternalLinkMutationOutcome.capabilityDisabled) {
      _replaceWithParent();
    }
  }

  @override
  Widget build(BuildContext context) {
    final draft = widget.draft;

    return StreamValueBuilder<bool>(
      streamValue: draft.busyStreamValue,
      builder: (context, isBusy) => StreamValueBuilder<bool>(
        streamValue: draft.dirtyStreamValue,
        builder: (context, isDirty) => PopScope(
          canPop: !isBusy && !isDirty,
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) return;
            if (isBusy) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Aguarde a conclusão da alteração.'),
                ),
              );
              return;
            }
            unawaited(_confirmDiscardAndExit(draft));
          },
          child: Scaffold(
            appBar: AppBar(
              title: Text(
                draft.isEditing
                    ? draft.selectedTypeStreamValue.value.semanticLabel
                    : 'Adicionar link',
              ),
            ),
            body: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: StreamValueBuilder<AccountProfileExternalLinkType>(
                    streamValue: draft.selectedTypeStreamValue,
                    builder: (context, type) => StreamValueBuilder<bool>(
                      streamValue: draft.requiresReloadStreamValue,
                      builder: (context, requiresReload) => StreamValueBuilder<bool>(
                        streamValue: draft.canSubmitStreamValue,
                        builder: (context, canSubmit) => ListView(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                          children: [
                            if (draft.isEditing) ...[
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 30,
                                    child: Icon(
                                      AccountProfileExternalLinkIconRegistry.iconFor(
                                        type,
                                      ),
                                      size: 28,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Text(
                                      type.semanticLabel,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleLarge,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 28),
                            ],
                            Form(
                              key: draft.formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  if (!draft.isEditing) ...[
                                    DropdownButtonFormField<
                                      AccountProfileExternalLinkType
                                    >(
                                      key: const Key('externalLinkTypeField'),
                                      initialValue: type,
                                      decoration: const InputDecoration(
                                        labelText: 'Tipo de link',
                                        border: OutlineInputBorder(),
                                      ),
                                      items: [
                                        for (final option in _availableTypes(
                                          draft,
                                        ))
                                          DropdownMenuItem(
                                            value: option,
                                            child: Text(option.semanticLabel),
                                          ),
                                      ],
                                      onChanged: isBusy || requiresReload
                                          ? null
                                          : (value) {
                                              if (value != null) {
                                                _controller
                                                    .selectExternalLinkType(
                                                      draft,
                                                      value,
                                                    );
                                              }
                                            },
                                    ),
                                    const SizedBox(height: 20),
                                  ],
                                  TextFormField(
                                    key: const Key('externalLinkUrlField'),
                                    controller: draft.urlController,
                                    enabled: !isBusy && !requiresReload,
                                    keyboardType: TextInputType.url,
                                    autocorrect: false,
                                    decoration: InputDecoration(
                                      labelText: 'URL HTTPS',
                                      helperText:
                                          'Cole o endereço oficial de ${type.semanticLabel}.',
                                      border: const OutlineInputBorder(),
                                    ),
                                    validator: (value) => _controller
                                        .validateExternalLinkUrl(draft, value),
                                  ),
                                  if (type ==
                                      AccountProfileExternalLinkType
                                          .website) ...[
                                    const SizedBox(height: 20),
                                    TextFormField(
                                      key: const Key('externalLinkLabelField'),
                                      controller: draft.labelController,
                                      enabled: !isBusy && !requiresReload,
                                      maxLength: 255,
                                      decoration: const InputDecoration(
                                        labelText: 'Nome do site',
                                        helperText:
                                            'Este nome identifica o destino para acessibilidade.',
                                        border: OutlineInputBorder(),
                                      ),
                                      validator: (value) =>
                                          _controller.validateExternalLinkLabel(
                                            draft,
                                            value,
                                          ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            StreamValueBuilder<String>(
                              streamValue: draft.errorStreamValue,
                              onNullWidget: const SizedBox.shrink(),
                              builder: (context, error) => Text(
                                error,
                                key: const Key('externalLinkMutationError'),
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                            ),
                            if (requiresReload) ...[
                              const SizedBox(height: 12),
                              OutlinedButton.icon(
                                key: const Key('externalLinkReloadButton'),
                                onPressed: isBusy
                                    ? null
                                    : () => _controller
                                          .reloadExternalLinkBaseline(draft),
                                icon: const Icon(Icons.refresh),
                                label: const Text('Recarregar perfil'),
                              ),
                            ],
                            const SizedBox(height: 28),
                            SizedBox(
                              height: 52,
                              child: FilledButton(
                                key: const Key('externalLinkSaveButton'),
                                onPressed:
                                    isBusy || requiresReload || !canSubmit
                                    ? null
                                    : () => _save(draft),
                                child: isBusy
                                    ? const SizedBox.square(
                                        dimension: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text('Salvar link'),
                              ),
                            ),
                            if (draft.isEditing) ...[
                              const SizedBox(height: 40),
                              const Divider(),
                              const SizedBox(height: 12),
                              TextButton.icon(
                                key: const Key('externalLinkDeleteButton'),
                                onPressed: isBusy || requiresReload
                                    ? null
                                    : () => _delete(draft),
                                style: TextButton.styleFrom(
                                  foregroundColor: Theme.of(
                                    context,
                                  ).colorScheme.error,
                                ),
                                icon: const Icon(Icons.delete_outline),
                                label: const Text('Remover link'),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

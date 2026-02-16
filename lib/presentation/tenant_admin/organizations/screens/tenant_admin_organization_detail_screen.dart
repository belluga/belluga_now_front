import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_organization.dart';
import 'package:belluga_now/presentation/tenant_admin/organizations/controllers/tenant_admin_organizations_controller.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/utils/tenant_admin_form_value_utils.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_error_banner.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_field_edit_sheet.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class TenantAdminOrganizationDetailScreen extends StatefulWidget {
  const TenantAdminOrganizationDetailScreen({
    super.key,
    required this.organizationId,
  });

  final String organizationId;

  @override
  State<TenantAdminOrganizationDetailScreen> createState() =>
      _TenantAdminOrganizationDetailScreenState();
}

class _TenantAdminOrganizationDetailScreenState
    extends State<TenantAdminOrganizationDetailScreen> {
  final TenantAdminOrganizationsController _controller =
      GetIt.I.get<TenantAdminOrganizationsController>();

  @override
  void initState() {
    super.initState();
    _controller.loadOrganizationDetail(widget.organizationId);
  }

  Future<void> _editName(TenantAdminOrganization organization) async {
    final result = await showTenantAdminFieldEditSheet(
      context: context,
      title: 'Editar nome da organizacao',
      label: 'Nome',
      initialValue: organization.name,
      textCapitalization: TextCapitalization.words,
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
    final next = result.value.trim();
    if (next.isEmpty || next == organization.name) {
      return;
    }
    final updated = await _controller.updateOrganization(
      organizationId: organization.id,
      name: next,
    );
    if (!mounted || updated == null) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Nome da organizacao atualizado.')),
    );
  }

  Future<void> _editSlug(TenantAdminOrganization organization) async {
    final result = await showTenantAdminFieldEditSheet(
      context: context,
      title: 'Editar slug da organizacao',
      label: 'Slug',
      initialValue: organization.slug ?? '',
      helperText: 'Deve ser unico no tenant.',
      inputFormatters: tenantAdminSlugInputFormatters,
      validator: (value) => tenantAdminValidateRequiredSlug(
        value,
        requiredMessage: 'Slug e obrigatorio.',
      ),
    );
    if (result == null || !mounted) {
      return;
    }
    final next = result.value.trim();
    if (next.isEmpty || next == organization.slug) {
      return;
    }
    final updated = await _controller.updateOrganization(
      organizationId: organization.id,
      slug: next,
    );
    if (!mounted || updated == null) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Slug da organizacao atualizado.')),
    );
  }

  Future<void> _editDescription(TenantAdminOrganization organization) async {
    final result = await showTenantAdminFieldEditSheet(
      context: context,
      title: 'Editar descricao',
      label: 'Descricao',
      initialValue: organization.description ?? '',
      helperText: 'Campo opcional.',
      textCapitalization: TextCapitalization.sentences,
      autocorrect: true,
      enableSuggestions: true,
    );
    if (result == null || !mounted) {
      return;
    }
    final next = result.value.trim();
    final current = organization.description?.trim() ?? '';
    if (next == current) {
      return;
    }
    final updated = await _controller.updateOrganization(
      organizationId: organization.id,
      description: next,
    );
    if (!mounted || updated == null) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Descricao da organizacao atualizada.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamValueBuilder<bool>(
      streamValue: _controller.organizationDetailLoadingStreamValue,
      builder: (context, isLoading) {
        return StreamValueBuilder<String?>(
          streamValue: _controller.organizationDetailErrorStreamValue,
          builder: (context, error) {
            return StreamValueBuilder<TenantAdminOrganization?>(
              streamValue: _controller.organizationDetailStreamValue,
              builder: (context, organization) {
                return Scaffold(
                  appBar: AppBar(
                    title: const Text('Organizacao'),
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => context.router.maybePop(),
                      tooltip: 'Voltar',
                    ),
                  ),
                  body: Padding(
                    padding: const EdgeInsets.all(16),
                    child: isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : error != null
                            ? TenantAdminErrorBanner(
                                rawError: error,
                                fallbackMessage:
                                    'Nao foi possivel carregar a organizacao.',
                                onRetry: () => _controller
                                    .loadOrganizationDetail(widget.organizationId),
                              )
                            : organization == null
                                ? const Center(child: Text('Organizacao nao encontrada.'))
                                : Card(
                                    margin: EdgeInsets.zero,
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Detalhes',
                                            style:
                                                Theme.of(context).textTheme.titleMedium,
                                          ),
                                          const SizedBox(height: 12),
                                          _editableRow(
                                            label: 'Nome',
                                            value: organization.name,
                                            onEdit: () => _editName(organization),
                                          ),
                                          const SizedBox(height: 8),
                                          _editableRow(
                                            label: 'Slug',
                                            value: organization.slug ?? '-',
                                            onEdit: () => _editSlug(organization),
                                          ),
                                          const SizedBox(height: 8),
                                          _editableRow(
                                            label: 'Descricao',
                                            value: organization.description?.trim().isNotEmpty ==
                                                    true
                                                ? organization.description!.trim()
                                                : '-',
                                            onEdit: () => _editDescription(organization),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _editableRow({
    required String label,
    required String value,
    required VoidCallback onEdit,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 96,
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

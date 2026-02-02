import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/presentation/common/widgets/belluga_network_image.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_profile_type.dart';
import 'package:belluga_now/presentation/tenant_admin/account_profiles/controllers/tenant_admin_account_profiles_controller.dart';
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
    _profilesController.loadAccountDetail(widget.accountSlug);
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
            accountSlug: widget.accountSlug,
          ),
        )
        .then((_) => _profilesController.loadAccountDetail(widget.accountSlug));
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
        .then((_) => _profilesController.loadAccountDetail(widget.accountSlug));
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

                    return Scaffold(
                      appBar: AppBar(
                        title: Text('Conta: ${widget.accountSlug}'),
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
                                ? Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        errorMessage,
                                        style:
                                            const TextStyle(color: Colors.red),
                                      ),
                                      const SizedBox(height: 12),
                                      TextButton(
                                        onPressed: () => _profilesController
                                            .loadAccountDetail(
                                          widget.accountSlug,
                                        ),
                                        child: const Text('Tentar novamente'),
                                      ),
                                    ],
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
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Detalhes da conta',
                                    style:
                                        Theme.of(context).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 12),
                                  _buildRow('Slug', account?.slug ?? '-'),
                                  const SizedBox(height: 8),
                                  _buildRow(
                                    'Documento',
                                    account?.document.number ?? '-',
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
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                      child: const Text('Criar Perfil'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ] else ...[
                            Card(
                              margin: EdgeInsets.zero,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Perfil da conta',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium,
                                    ),
                                    const SizedBox(height: 12),
                                    if (coverUrl != null && coverUrl.isNotEmpty)
                                      BellugaNetworkImage(
                                        coverUrl,
                                        height: 160,
                                        fit: BoxFit.cover,
                                        clipBorderRadius:
                                            BorderRadius.circular(12),
                                        errorWidget: Container(
                                          height: 160,
                                          decoration: BoxDecoration(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .surfaceContainerHighest,
                                          ),
                                          child: const Center(
                                            child: Icon(
                                              Icons.image_not_supported,
                                            ),
                                          ),
                                        ),
                                      )
                                    else
                                      Container(
                                        height: 160,
                                        decoration: BoxDecoration(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .surfaceContainerHighest,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Center(
                                          child: Icon(Icons.image_outlined),
                                        ),
                                      ),
                                    const SizedBox(height: 16),
                                    Row(
                                      children: [
                                        if (avatarUrl != null &&
                                            avatarUrl.isNotEmpty)
                                          BellugaNetworkImage(
                                            avatarUrl,
                                            width: 72,
                                            height: 72,
                                            fit: BoxFit.cover,
                                            clipBorderRadius:
                                                BorderRadius.circular(36),
                                            errorWidget: Container(
                                              width: 72,
                                              height: 72,
                                              decoration: BoxDecoration(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .surfaceContainerHighest,
                                              ),
                                              child: const Icon(
                                                Icons.person_off_outlined,
                                              ),
                                            ),
                                          )
                                        else
                                          Container(
                                            width: 72,
                                            height: 72,
                                            decoration: BoxDecoration(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .surfaceContainerHighest,
                                              borderRadius:
                                                  BorderRadius.circular(36),
                                            ),
                                            child: const Icon(
                                              Icons.person_outline,
                                            ),
                                          ),
                                        const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        profile.displayName,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium,
                                      ),
                                    ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    _buildRow('Tipo', _profileTypeLabel(types)),
                                    const SizedBox(height: 8),
                                    if (location != null)
                                      _buildRow(
                                        'Localização',
                                        '${location.latitude.toStringAsFixed(6)}, '
                                        '${location.longitude.toStringAsFixed(6)}',
                                      ),
                                    const SizedBox(height: 12),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: OutlinedButton.icon(
                                        onPressed: _openEdit,
                                        icon: const Icon(Icons.edit_outlined),
                                        label: const Text('Editar Perfil'),
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
}

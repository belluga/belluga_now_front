import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_profile_type.dart';
import 'package:belluga_now/presentation/tenant_admin/account_profiles/controllers/tenant_admin_account_profiles_controller.dart';
import 'package:belluga_now/presentation/tenant_admin/account_profiles/screens/tenant_admin_account_profile_edit_screen.dart';
import 'package:belluga_now/presentation/tenant_admin/accounts/controllers/tenant_admin_location_picker_controller.dart';
import 'package:flutter/material.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class TenantAdminAccountDetailScreen extends StatefulWidget {
  const TenantAdminAccountDetailScreen({
    super.key,
    required this.accountSlug,
    required this.profilesController,
    required this.locationPickerController,
  });

  final String accountSlug;
  final TenantAdminAccountProfilesController profilesController;
  final TenantAdminLocationPickerController locationPickerController;

  @override
  State<TenantAdminAccountDetailScreen> createState() =>
      _TenantAdminAccountDetailScreenState();
}

class _TenantAdminAccountDetailScreenState
    extends State<TenantAdminAccountDetailScreen> {
  late final TenantAdminAccountProfilesController _profilesController;
  TenantAdminAccount? _account;
  TenantAdminAccountProfile? _profile;
  String? _errorMessage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _profilesController = widget.profilesController;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await _profilesController.loadProfileTypes();
      final account =
          await _profilesController.resolveAccountBySlug(widget.accountSlug);
      final profile =
          await _profilesController.fetchProfileForAccount(account.id);
      if (!mounted) return;
      _account = account;
      _profile = profile;
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _profileTypeLabel(List<TenantAdminProfileTypeDefinition> types) {
    final profile = _profile;
    if (profile == null) return '-';
    for (final type in types) {
      if (type.type == profile.profileType) {
        return type.label;
      }
    }
    return profile.profileType;
  }

  Future<void> _openCreate() async {
    final router = context.router;
    await router.push(
      TenantAdminAccountProfileCreateRoute(
        accountSlug: widget.accountSlug,
      ),
    );
    await _load();
  }

  Future<void> _openEdit() async {
    final profile = _profile;
    if (profile == null) {
      return;
    }
    final navigator = Navigator.of(context);
    await navigator.push(
      MaterialPageRoute(
        builder: (_) => TenantAdminAccountProfileEditScreen(
          accountProfileId: profile.id,
          controller: _profilesController,
          locationPickerController: widget.locationPickerController,
        ),
      ),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final account = _account;
    return Scaffold(
      appBar: AppBar(
        title: Text('Conta: ${widget.accountSlug}'),
        actions: [
          if (_profile != null)
            FilledButton.tonalIcon(
              onPressed: _isLoading ? null : _openEdit,
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Editar'),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: _load,
                        child: const Text('Tentar novamente'),
                      ),
                    ],
                  )
                : StreamValueBuilder(
                    streamValue: _profilesController.profileTypesStreamValue,
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
                          if (_profile == null) ...[
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
                                    if (_profile?.coverUrl != null &&
                                        _profile!.coverUrl!.isNotEmpty)
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.network(
                                          _profile!.coverUrl!,
                                          height: 160,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                            return Container(
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
                                            );
                                          },
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
                                        if (_profile?.avatarUrl != null &&
                                            _profile!.avatarUrl!.isNotEmpty)
                                          ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(36),
                                            child: Image.network(
                                              _profile!.avatarUrl!,
                                              width: 72,
                                              height: 72,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                return Container(
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
                                                );
                                              },
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
                                            _profile?.displayName ?? '-',
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
                                    if (_profile?.location != null)
                                      _buildRow(
                                        'Localização',
                                        '${_profile!.location!.latitude.toStringAsFixed(6)}, '
                                        '${_profile!.location!.longitude.toStringAsFixed(6)}',
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

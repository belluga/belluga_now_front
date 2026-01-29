import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/presentation/tenant_admin/account_profiles/controllers/tenant_admin_account_profiles_controller.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class TenantAdminAccountProfilesListScreen extends StatefulWidget {
  const TenantAdminAccountProfilesListScreen({
    super.key,
    required this.accountSlug,
  });

  final String accountSlug;

  @override
  State<TenantAdminAccountProfilesListScreen> createState() =>
      _TenantAdminAccountProfilesListScreenState();
}

class _TenantAdminAccountProfilesListScreenState
    extends State<TenantAdminAccountProfilesListScreen> {
  late final TenantAdminAccountProfilesController _controller;
  String? _accountId;

  @override
  void initState() {
    super.initState();
    _controller = GetIt.I.get<TenantAdminAccountProfilesController>();
    _load();
  }

  Future<void> _load() async {
    final account =
        await _controller.resolveAccountBySlug(widget.accountSlug);
    if (!mounted) return;
    _accountId = account.id;
    await _controller.loadProfiles(account.id);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamValueBuilder(
      streamValue: _controller.profilesStreamValue,
      builder: (context, profiles) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => context.router.maybePop(),
                  tooltip: 'Voltar',
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Perfis - ${widget.accountSlug}',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: _accountId == null
                      ? null
                      : () {
                          context.router.push(
                            TenantAdminAccountProfileCreateRoute(
                              accountSlug: widget.accountSlug,
                            ),
                          );
                        },
                  child: const Text('Criar'),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: profiles.isEmpty
                    ? _buildEmptyState()
                    : ListView.separated(
                        itemCount: profiles.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final profile = profiles[index];
                          return ListTile(
                            title: Text(profile.displayName),
                            subtitle: Text(profile.profileType),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              context.router.push(
                                TenantAdminAccountProfileDetailRoute(
                                  accountProfileId: profile.id,
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Text('Nenhum perfil para esta conta ainda.'),
    );
  }
}

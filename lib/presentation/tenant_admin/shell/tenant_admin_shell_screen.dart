import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/domain/repositories/admin_mode_repository_contract.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class TenantAdminShellScreen extends StatefulWidget {
  const TenantAdminShellScreen({super.key});

  @override
  State<TenantAdminShellScreen> createState() =>
      _TenantAdminShellScreenState();
}

class _TenantAdminShellScreenState extends State<TenantAdminShellScreen> {
  bool _showAdminBanner = true;

  @override
  Widget build(BuildContext context) {
    final adminMode = GetIt.I.get<AdminModeRepositoryContract>();
    return StreamValueBuilder<AdminMode>(
      streamValue: adminMode.modeStreamValue,
      builder: (context, mode) {
        final isAdmin = mode == AdminMode.landlord;
        return Scaffold(
          appBar: AppBar(
            title: const Text('MODO ADMINISTRADOR'),
            actions: [
              TextButton(
                onPressed: () async {
                  await adminMode.setUserMode();
                  if (!context.mounted) return;
                  context.router.replaceAll([const ProfileRoute()]);
                },
                child: const Text('Perfil'),
              ),
            ],
          ),
          body: Column(
            children: [
              if (isAdmin && _showAdminBanner)
                MaterialBanner(
                  content: const Text('Modo Admin ativo'),
                  actions: [
                    TextButton(
                      onPressed: () {
                        setState(() => _showAdminBanner = false);
                      },
                      child: const Text('Ok'),
                    ),
                  ],
                ),
              const Expanded(child: AutoRouter()),
            ],
          ),
        );
      },
    );
  }
}

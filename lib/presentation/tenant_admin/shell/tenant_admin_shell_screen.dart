import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/domain/repositories/admin_mode_repository_contract.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class TenantAdminShellScreen extends StatelessWidget {
  const TenantAdminShellScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final adminMode = GetIt.I.get<AdminModeRepositoryContract>();
    return StreamValueBuilder<AdminMode>(
      streamValue: adminMode.modeStreamValue,
      builder: (context, mode) {
        final isAdmin = mode == AdminMode.landlord;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Admin'),
            actions: const [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Chip(label: Text('Admin')),
              ),
            ],
          ),
          body: Column(
            children: [
              if (isAdmin)
                MaterialBanner(
                  content: const Text('Modo Admin ativo'),
                  actions: [
                    TextButton(
                      onPressed: () {},
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

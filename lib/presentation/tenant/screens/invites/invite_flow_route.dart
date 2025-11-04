import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/modular_app/modules/invites_module.dart';
import 'package:belluga_now/presentation/tenant/screens/invites/invite_flow_screen.dart';
import 'package:flutter/material.dart';
import 'package:get_it_modular_with_auto_route/get_it_modular_with_auto_route.dart';

@RoutePage(name: 'InviteFlowRoute')
class InviteFlowRoutePage extends StatelessWidget {
  const InviteFlowRoutePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModuleScope<InvitesModule>(
      child: InviteFlowScreen(),
    );
  }
}

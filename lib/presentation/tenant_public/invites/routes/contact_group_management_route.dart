import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/modular_app/modules/invites_module.dart';
import 'package:belluga_now/presentation/tenant_public/invites/screens/contact_group_management/contact_group_management_screen.dart';
import 'package:flutter/material.dart';
import 'package:get_it_modular_with_auto_route/get_it_modular_with_auto_route.dart';

@RoutePage(name: 'ContactGroupManagementRoute')
class ContactGroupManagementRoutePage extends StatelessWidget {
  const ContactGroupManagementRoutePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ModuleScope<InvitesModule>(
      child: const ContactGroupManagementScreen(),
    );
  }
}

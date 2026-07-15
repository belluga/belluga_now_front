import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/modular_app/modules/profile_module.dart';
import 'package:belluga_now/presentation/tenant_public/profile/screens/account_deletion_resolution_screen/account_deletion_resolution_screen.dart';
import 'package:flutter/material.dart';
import 'package:get_it_modular_with_auto_route/get_it_modular_with_auto_route.dart';

@RoutePage(name: 'AccountDeletionResolutionRoute')
class AccountDeletionResolutionRoutePage extends StatelessWidget {
  const AccountDeletionResolutionRoutePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ModuleScope<ProfileModule>(
      child: const AccountDeletionResolutionScreen(),
    );
  }
}

import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/modular_app/modules/account_workspace_module.dart';
import 'package:belluga_now/presentation/account_workspace/screens/account_workspace_placeholder_screen.dart';
import 'package:flutter/material.dart';
import 'package:get_it_modular_with_auto_route/get_it_modular_with_auto_route.dart';

@RoutePage(name: 'AccountWorkspaceHomeRoute')
class AccountWorkspaceHomeRoutePage extends StatelessWidget {
  const AccountWorkspaceHomeRoutePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ModuleScope<AccountWorkspaceModule>(
      child: const AccountWorkspacePlaceholderScreen(),
    );
  }
}

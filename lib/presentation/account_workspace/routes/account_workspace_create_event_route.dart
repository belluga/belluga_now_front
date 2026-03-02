import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/presentation/account_workspace/screens/account_workspace_create_event_screen.dart';
import 'package:flutter/material.dart';

@RoutePage(name: 'AccountWorkspaceCreateEventRoute')
class AccountWorkspaceCreateEventRoutePage extends StatelessWidget {
  const AccountWorkspaceCreateEventRoutePage({
    @PathParam('accountSlug') required this.accountSlug,
    super.key,
  });

  final String accountSlug;

  @override
  Widget build(BuildContext context) {
    return AccountWorkspaceCreateEventScreen(accountSlug: accountSlug);
  }
}

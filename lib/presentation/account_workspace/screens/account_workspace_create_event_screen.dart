import 'package:belluga_now/presentation/tenant_admin/events/screens/tenant_admin_event_form_screen.dart';
import 'package:flutter/material.dart';

class AccountWorkspaceCreateEventScreen extends StatelessWidget {
  const AccountWorkspaceCreateEventScreen({
    required this.accountSlug,
    super.key,
  });

  final String accountSlug;

  @override
  Widget build(BuildContext context) {
    return TenantAdminEventFormScreen(
      accountSlugForOwnCreate: accountSlug,
    );
  }
}

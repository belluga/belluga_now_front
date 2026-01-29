import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/presentation/tenant_admin/account_profiles/screens/tenant_admin_account_profile_detail_screen.dart';
import 'package:flutter/material.dart';

@RoutePage(name: 'TenantAdminAccountProfileDetailRoute')
class TenantAdminAccountProfileDetailRoutePage extends StatelessWidget {
  const TenantAdminAccountProfileDetailRoutePage({
    super.key,
    required this.accountProfileId,
  });

  final String accountProfileId;

  @override
  Widget build(BuildContext context) {
    return TenantAdminAccountProfileDetailScreen(
      accountProfileId: accountProfileId,
    );
  }
}

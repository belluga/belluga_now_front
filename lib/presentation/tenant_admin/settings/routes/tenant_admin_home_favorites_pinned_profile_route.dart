import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/presentation/tenant_admin/settings/screens/tenant_admin_home_favorites_pinned_profile_screen.dart';
import 'package:flutter/material.dart';

@RoutePage(name: 'TenantAdminHomeFavoritesPinnedProfileRoute')
class TenantAdminHomeFavoritesPinnedProfileRoutePage extends StatelessWidget {
  const TenantAdminHomeFavoritesPinnedProfileRoutePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const TenantAdminHomeFavoritesPinnedProfileScreen();
  }
}

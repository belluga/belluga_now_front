import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/modular_app/modules/home_module.dart';
import 'package:belluga_now/presentation/tenant_public/legal/screens/tenant_privacy_policy_screen.dart';
import 'package:flutter/material.dart';
import 'package:get_it_modular_with_auto_route/get_it_modular_with_auto_route.dart';

@RoutePage(name: 'TenantPrivacyPolicyRoute')
class TenantPrivacyPolicyRoutePage extends StatelessWidget {
  const TenantPrivacyPolicyRoutePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ModuleScope<HomeModule>(
      child: const TenantPrivacyPolicyScreen(),
    );
  }
}

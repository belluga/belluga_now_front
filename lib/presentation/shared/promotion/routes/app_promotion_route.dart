import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/modular_app/modules/app_promotion_module.dart';
import 'package:belluga_now/presentation/shared/promotion/screens/app_promotion_screen/app_promotion_screen.dart';
import 'package:flutter/material.dart';
import 'package:get_it_modular_with_auto_route/get_it_modular_with_auto_route.dart';

@RoutePage(name: 'AppPromotionRoute')
class AppPromotionRoutePage extends StatelessWidget {
  const AppPromotionRoutePage({
    super.key,
    @QueryParam('redirect') this.redirectPath,
  });

  final String? redirectPath;

  @override
  Widget build(BuildContext context) {
    return ModuleScope<AppPromotionModule>(
      child: AppPromotionScreen(
        redirectPath: redirectPath,
      ),
    );
  }
}

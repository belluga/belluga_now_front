import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/application/router/support/canonical_route_governance.dart';
import 'package:belluga_now/presentation/landlord_area/auth/widgets/landlord_login_sheet.dart';
import 'package:belluga_now/presentation/landlord_area/home/screens/landlord_home_screen/controllers/landlord_home_login_sheet_controller.dart';
import 'package:belluga_now/presentation/landlord_area/home/screens/landlord_home_screen/controllers/landlord_home_screen_controller.dart';
import 'package:belluga_now/presentation/landlord_area/home/screens/landlord_home_screen/widgets/landlord_landing_app_bar.dart';
import 'package:belluga_now/presentation/landlord_area/home/screens/landlord_home_screen/widgets/landlord_landing_content.dart';
import 'package:belluga_now/presentation/shared/widgets/route_back_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class LandlordHomeScreen extends StatefulWidget {
  const LandlordHomeScreen({super.key});

  @override
  State<LandlordHomeScreen> createState() => _LandlordHomeScreenState();
}

class _LandlordHomeScreenState extends State<LandlordHomeScreen> {
  final LandlordHomeScreenController _controller =
      GetIt.I.get<LandlordHomeScreenController>();

  @override
  void initState() {
    super.initState();
    _controller.init();
  }

  @override
  Widget build(BuildContext context) {
    final backPolicy = buildCanonicalCurrentRouteBackPolicy(
      context,
      requestExit: _requestExit,
    );
    return StreamValueBuilder<LandlordHomeUiState>(
      streamValue: _controller.uiStateStreamValue,
      builder: (context, state) {
        return RouteBackScope(
          backPolicy: backPolicy,
          child: Scaffold(
            body: Stack(
              children: [
                LandlordLandingContent(
                  state: state,
                  controller: _controller,
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  child: LandlordLandingAppBar(
                    state: state,
                    onProblemPressed: _controller.scrollToProblem,
                    onSolutionPressed: _controller.scrollToSolution,
                    onEcosystemPressed: _controller.scrollToEcosystem,
                    onInstancesPressed: _controller.scrollToInstances,
                    onContactPressed: _controller.scrollToFooter,
                    onLoginPressed: _openLogin,
                    onMenuPressed: _controller.toggleMobileMenu,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  LandlordHomeLoginSheetController get _landlordLoginController =>
      GetIt.I.get<LandlordHomeLoginSheetController>();

  Future<void> _openLogin() async {
    final didLogin = await showLandlordLoginSheet(
      context,
      controller: _landlordLoginController,
    );
    _controller.refreshUiState();
    if (!didLogin || !_controller.canAccessAdminArea) {
      return;
    }
    _openAdminArea();
  }

  bool _openAdminArea() {
    if (!_controller.canAccessAdminArea) return false;
    final routerScope = StackRouterScope.of(context, watch: false);
    final router = routerScope?.controller;
    if (router == null) {
      return false;
    }

    router.replaceAll([const TenantAdminShellRoute()]);
    return true;
  }

  Future<void> _requestExit() async {
    await SystemNavigator.pop();
  }
}

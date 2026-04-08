import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/application/router/support/route_redirect_path.dart';
import 'package:belluga_now/presentation/shared/promotion/screens/app_promotion_screen/controllers/app_promotion_experience.dart';
import 'package:belluga_now/presentation/shared/promotion/screens/app_promotion_screen/controllers/app_promotion_screen_controller.dart';
import 'package:belluga_now/presentation/shared/promotion/screens/app_promotion_screen/controllers/app_promotion_tester_waitlist_controller.dart';
import 'package:belluga_now/presentation/shared/promotion/screens/app_promotion_screen/widgets/app_promotion_download_experience.dart';
import 'package:belluga_now/presentation/shared/promotion/screens/app_promotion_screen/widgets/app_promotion_tester_waitlist_experience.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

class AppPromotionScreen extends StatefulWidget {
  const AppPromotionScreen({
    super.key,
    this.redirectPath,
  });

  final String? redirectPath;

  @override
  State<AppPromotionScreen> createState() => _AppPromotionScreenState();
}

class _AppPromotionScreenState extends State<AppPromotionScreen> {
  final AppPromotionScreenController _controller =
      GetIt.I.get<AppPromotionScreenController>();
  final AppPromotionTesterWaitlistController _testerWaitlistController =
      GetIt.I.get<AppPromotionTesterWaitlistController>();

  @override
  void initState() {
    super.initState();
    if (_controller.currentExperience ==
        AppPromotionExperience.testerWaitlist) {
      _testerWaitlistController.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final redirectPath = _controller.normalizeRedirectPath(widget.redirectPath);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 780),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      key: const Key('app_promotion_close_button'),
                      onPressed: _dismiss,
                      icon: const Icon(Icons.close_rounded),
                      tooltip: 'Fechar',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Expanded(
                    child: switch (_controller.currentExperience) {
                      AppPromotionExperience.appDownload =>
                        AppPromotionDownloadExperience(
                          controller: _controller,
                          redirectPath: redirectPath,
                          onDismiss: _dismiss,
                        ),
                      AppPromotionExperience.testerWaitlist =>
                        AppPromotionTesterWaitlistExperience(
                          screenController: _controller,
                          controller: _testerWaitlistController,
                          onDismiss: _dismiss,
                        ),
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _dismiss() {
    final redirectPath = _controller.normalizeRedirectPath(widget.redirectPath);
    if (context.router.canPop()) {
      context.router.pop();
      return;
    }

    if (isAuthOwnedPromotionRedirectPath(redirectPath)) {
      unawaited(context.router.replaceAll([const TenantHomeRoute()]));
      return;
    }

    context.router.pop();
  }
}

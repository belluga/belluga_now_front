import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/presentation/shared/promotion/screens/app_promotion_screen/controllers/app_promotion_screen_controller.dart';
import 'package:belluga_now/presentation/shared/promotion/screens/app_promotion_screen/widgets/app_promotion_shared_widgets.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

class AppPromotionModal extends StatelessWidget {
  const AppPromotionModal({
    super.key,
    required this.controller,
    required this.redirectPath,
    this.title,
    this.supportingText,
  });

  final AppPromotionScreenController controller;
  final String redirectPath;
  final String? title;
  final String? supportingText;

  static Future<void> show(
    BuildContext context, {
    required String redirectPath,
    AppPromotionScreenController? controller,
    String? title,
    String? supportingText,
  }) {
    final resolvedController = controller ?? _resolveController();
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (dialogContext) => AppPromotionModal(
        controller: resolvedController,
        redirectPath: resolvedController.normalizeRedirectPath(redirectPath),
        title: title,
        supportingText: supportingText,
      ),
    );
  }

  static AppPromotionScreenController _resolveController() {
    if (GetIt.I.isRegistered<AppPromotionScreenController>()) {
      return GetIt.I.get<AppPromotionScreenController>();
    }
    return AppPromotionScreenController();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final iconUrl = controller.iconUrlForBrightness(theme.brightness);
    final resolvedTitle =
        title ?? '${controller.appDisplayName} fica melhor no app';
    final resolvedSupportingText = supportingText ??
        'Continue no app para destravar as ações e a experiência completa.';

    return SafeArea(
      key: const Key('app_promotion_modal'),
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          bottom: 16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            key: const Key('app_promotion_modal_body'),
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                resolvedTitle,
                key: const Key('app_promotion_modal_title'),
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  height: 1.12,
                ),
              ),
              if (resolvedSupportingText.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  resolvedSupportingText.trim(),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Center(
                child: AppPromotionBrandIcon(
                  colorScheme: colorScheme,
                  iconUrl: iconUrl,
                  size: 76,
                  iconSize: 46,
                  borderRadius: 22,
                ),
              ),
              const SizedBox(height: 16),
              AppPromotionStoreActions(
                controller: controller,
                redirectPath: redirectPath,
                compact: true,
              ),
              TextButton(
                key: const Key('app_promotion_modal_dismiss_button'),
                onPressed: () => context.router.maybePop(),
                child: const Text('Agora não'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

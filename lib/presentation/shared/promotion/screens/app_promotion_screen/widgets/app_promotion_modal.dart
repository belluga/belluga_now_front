import 'package:belluga_now/presentation/shared/promotion/screens/app_promotion_screen/controllers/app_promotion_screen_controller.dart';
import 'package:belluga_now/presentation/shared/promotion/screens/app_promotion_screen/widgets/app_promotion_shared_widgets.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

class AppPromotionModal extends StatelessWidget {
  const AppPromotionModal({
    super.key,
    required this.controller,
    required this.redirectPath,
  });

  final AppPromotionScreenController controller;
  final String redirectPath;

  static Future<void> show(
    BuildContext context, {
    required String redirectPath,
    AppPromotionScreenController? controller,
  }) {
    final resolvedController = controller ?? _resolveController();
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AppPromotionModal(
        controller: resolvedController,
        redirectPath: resolvedController.normalizeRedirectPath(redirectPath),
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
    final title = '${controller.appDisplayName} fica melhor no app';

    return AlertDialog(
      key: const Key('app_promotion_modal'),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      title: Text(
        title,
        key: const Key('app_promotion_modal_title'),
        textAlign: TextAlign.center,
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
          height: 1.15,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppPromotionBrandIcon(
              colorScheme: colorScheme,
              iconUrl: iconUrl,
              size: 72,
              iconSize: 42,
              borderRadius: 20,
            ),
            const SizedBox(height: 16),
            Text(
              'Continue no app para destravar as ações e a experiência completa.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            AppPromotionStoreActions(
              controller: controller,
              redirectPath: redirectPath,
              compact: true,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          key: const Key('app_promotion_modal_dismiss_button'),
          onPressed: () => Navigator.of(context).maybePop(),
          child: const Text('Agora não'),
        ),
      ],
    );
  }
}

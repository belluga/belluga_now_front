import 'package:belluga_now/presentation/shared/promotion/screens/app_promotion_screen/controllers/app_promotion_screen_controller.dart';
import 'package:belluga_now/presentation/shared/promotion/screens/app_promotion_screen/widgets/app_promotion_shared_widgets.dart';
import 'package:flutter/material.dart';

class AppPromotionDownloadExperience extends StatelessWidget {
  const AppPromotionDownloadExperience({
    super.key,
    required this.controller,
    required this.redirectPath,
    required this.onDismiss,
  });

  final AppPromotionScreenController controller;
  final String redirectPath;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final iconUrl = controller.iconUrlForBrightness(theme.brightness);
    final title = '${controller.appDisplayName} fica melhor no app';

    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 24, 12, 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AppPromotionBrandIcon(
                            colorScheme: colorScheme,
                            iconUrl: iconUrl,
                          ),
                          const SizedBox(height: 20),
                          Text(
                            title,
                            key: const Key('app_promotion_title'),
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              height: 1.15,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Continue no app para destravar as ações e a experiência completa.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 44),
                          Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 300),
                              child: const Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _BenefitRow(
                                      label: 'Enviar e aceitar convites'),
                                  SizedBox(height: 14),
                                  _BenefitRow(
                                    label:
                                        'Favoritar artistas, locais e eventos',
                                  ),
                                  SizedBox(height: 14),
                                  _BenefitRow(
                                    label: 'Receber lembretes da sua agenda',
                                  ),
                                  SizedBox(height: 14),
                                  _BenefitRow(
                                    label: 'Check-ins e benefícios (em breve)',
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 44),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppPromotionStoreActions(
                controller: controller,
                redirectPath: redirectPath,
              ),
              const SizedBox(height: 12),
              TextButton(
                key: const Key('app_promotion_dismiss_button'),
                onPressed: onDismiss,
                child: const Text('AGORA NÃO'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BenefitRow extends StatelessWidget {
  const _BenefitRow({
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(
            Icons.check_circle_rounded,
            size: 18,
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

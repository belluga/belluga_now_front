import 'dart:async';

import 'package:belluga_now/presentation/shared/promotion/screens/app_promotion_screen/controllers/app_promotion_screen_controller.dart';
import 'package:belluga_now/presentation/shared/promotion/screens/app_promotion_screen/controllers/app_promotion_store_platform.dart';
import 'package:belluga_now/presentation/shared/widgets/belluga_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AppPromotionDownloadExperience extends StatelessWidget {
  const AppPromotionDownloadExperience({
    super.key,
    required this.controller,
    required this.redirectPath,
    required this.onDismiss,
  });

  static const _iosBadgeAsset =
      'assets/images/store_badges/download_on_the_app_store.svg';
  static const _androidBadgeAsset =
      'assets/images/store_badges/get_it_on_google_play.png';

  final AppPromotionScreenController controller;
  final String redirectPath;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final storePlatforms = controller.storePlatformsToRender;
    final iconUrl = controller.iconUrlForBrightness(theme.brightness);
    final iosPromotionUri =
        controller.buildIosPromotionUri(redirectPath: redirectPath);
    final androidPromotionUri =
        controller.buildAndroidPromotionUri(redirectPath: redirectPath);
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
                          _BrandIcon(
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
              Text(
                storePlatforms.length == 1
                    ? 'Baixe para continuar'
                    : 'Escolha sua loja',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              if (storePlatforms.contains(AppPromotionStorePlatform.ios))
                _StoreBadgeButton(
                  key: const Key('app_promotion_store_badge_ios'),
                  onTap: iosPromotionUri == null
                      ? null
                      : () => _launch(
                            uri: iosPromotionUri,
                            platform: AppPromotionStorePlatform.ios,
                          ),
                  child: SvgPicture.asset(
                    _iosBadgeAsset,
                    height: 56,
                    fit: BoxFit.contain,
                  ),
                ),
              if (storePlatforms
                  .contains(AppPromotionStorePlatform.android)) ...[
                if (storePlatforms.contains(AppPromotionStorePlatform.ios))
                  const SizedBox(height: 12),
                _StoreBadgeButton(
                  key: const Key('app_promotion_store_badge_android'),
                  onTap: androidPromotionUri == null
                      ? null
                      : () => _launch(
                            uri: androidPromotionUri,
                            platform: AppPromotionStorePlatform.android,
                          ),
                  child: Image.asset(
                    _androidBadgeAsset,
                    height: 84,
                    fit: BoxFit.contain,
                  ),
                ),
              ],
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

  void _launch({
    required Uri uri,
    required AppPromotionStorePlatform platform,
  }) {
    unawaited(
      controller.launchPromotionUri(
        uri: uri,
        platform: platform,
      ),
    );
  }
}

class _BrandIcon extends StatelessWidget {
  const _BrandIcon({
    required this.colorScheme,
    required this.iconUrl,
  });

  final ColorScheme colorScheme;
  final String? iconUrl;

  @override
  Widget build(BuildContext context) {
    final iconChild = iconUrl == null
        ? Icon(
            Icons.phone_iphone_rounded,
            size: 40,
            color: colorScheme.onPrimaryContainer,
          )
        : BellugaNetworkImage(
            iconUrl!,
            width: 56,
            height: 56,
            fit: BoxFit.contain,
            errorWidget: Icon(
              Icons.phone_iphone_rounded,
              size: 40,
              color: colorScheme.onPrimaryContainer,
            ),
          );
    return Container(
      key: const Key('app_promotion_brand_icon'),
      width: 96,
      height: 96,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.18),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: iconChild,
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

class _StoreBadgeButton extends StatelessWidget {
  const _StoreBadgeButton({
    super.key,
    required this.child,
    this.onTap,
  });

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onTap == null ? 0.5 : 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: child,
      ),
    );
  }
}

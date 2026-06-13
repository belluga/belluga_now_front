import 'dart:async';

import 'package:belluga_now/presentation/shared/promotion/screens/app_promotion_screen/controllers/app_promotion_screen_controller.dart';
import 'package:belluga_now/presentation/shared/promotion/screens/app_promotion_screen/controllers/app_promotion_store_platform.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AppPromotionStoreActions extends StatelessWidget {
  const AppPromotionStoreActions({
    super.key,
    required this.controller,
    required this.redirectPath,
    this.compact = false,
  });

  static const _iosBadgeAsset =
      'assets/images/store_badges/download_on_the_app_store.svg';
  static const _androidBadgeAsset =
      'assets/images/store_badges/get_it_on_google_play.png';

  final AppPromotionScreenController controller;
  final String redirectPath;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final storePlatforms = controller.storePlatformsToRender;
    final iosPromotionUri =
        controller.buildIosPromotionUri(redirectPath: redirectPath);
    final androidPromotionUri =
        controller.buildAndroidPromotionUri(redirectPath: redirectPath);

    return Column(
      key: const Key('app_promotion_store_actions'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          storePlatforms.isEmpty
              ? 'App em preparação'
              : storePlatforms.length == 1
                  ? 'Baixe para continuar'
                  : 'Escolha sua loja',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: compact ? 10 : 12),
        if (storePlatforms.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 24),
            child: Text(
              'A publicação nas lojas ainda não está ativa.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
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
              height: compact ? 48 : 56,
              fit: BoxFit.contain,
            ),
          ),
        if (storePlatforms.contains(AppPromotionStorePlatform.android)) ...[
          if (storePlatforms.contains(AppPromotionStorePlatform.ios))
            SizedBox(height: compact ? 8 : 12),
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
              height: compact ? 72 : 84,
              fit: BoxFit.contain,
            ),
          ),
        ],
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

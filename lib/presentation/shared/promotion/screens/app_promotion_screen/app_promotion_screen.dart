import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/presentation/shared/promotion/screens/app_promotion_screen/controllers/app_promotion_screen_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
  static const _iosBadgeAsset =
      'assets/images/store_badges/download_on_the_app_store.svg';
  static const _androidBadgeAsset =
      'assets/images/store_badges/get_it_on_google_play.png';

  final AppPromotionScreenController _controller =
      GetIt.I.get<AppPromotionScreenController>();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final redirectPath = _controller.normalizeRedirectPath(widget.redirectPath);
    final iosPromotionUri =
        _controller.buildIosPromotionUri(redirectPath: redirectPath);
    final androidPromotionUri =
        _controller.buildAndroidPromotionUri(redirectPath: redirectPath);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Baixe o app'),
        leading: BackButton(
          onPressed: () {
            final router = context.router;
            if (router.canPop()) {
              router.pop();
              return;
            }
            router.replaceAll([const TenantHomeRoute()]);
          },
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: colorScheme.outlineVariant,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.rocket_launch_rounded,
                        size: 56,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Leve a experiência completa para o app',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No app você entra na sua conta, confirma presença, envia convites e destrava as ações de confiança.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Escolha sua loja',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _StoreBadgeButton(
                        key: const Key('app_promotion_store_badge_ios'),
                        onTap: iosPromotionUri == null
                            ? null
                            : () => _launch(
                                  uri: iosPromotionUri,
                                  platformTarget: 'ios',
                                ),
                        child: SvgPicture.asset(
                          _iosBadgeAsset,
                          height: 56,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _StoreBadgeButton(
                        key: const Key('app_promotion_store_badge_android'),
                        onTap: androidPromotionUri == null
                            ? null
                            : () => _launch(
                                  uri: androidPromotionUri,
                                  platformTarget: 'android',
                                ),
                        child: Image.asset(
                          _androidBadgeAsset,
                          height: 84,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Os links da App Store e do Google Play são resolvidos dinamicamente por tenant.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _launch({
    required Uri uri,
    required String platformTarget,
  }) {
    unawaited(
      _controller.launchPromotionUri(
        uri: uri,
        platformTarget: platformTarget,
      ),
    );
  }
}

class _StoreBadgeButton extends StatelessWidget {
  const _StoreBadgeButton({
    super.key,
    required this.child,
    required this.onTap,
  });

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onTap != null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: child,
        ),
      ),
    );
  }
}

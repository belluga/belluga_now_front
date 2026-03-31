import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/presentation/shared/promotion/screens/app_promotion_screen/controllers/app_promotion_store_platform.dart';
import 'package:belluga_now/presentation/shared/promotion/screens/app_promotion_screen/controllers/app_promotion_screen_controller.dart';
import 'package:belluga_now/presentation/shared/widgets/belluga_network_image.dart';
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
    final storePlatforms = _controller.storePlatformsToRender;
    final iconUrl = _controller.iconUrlForBrightness(theme.brightness);
    final iosPromotionUri =
        _controller.buildIosPromotionUri(redirectPath: redirectPath);
    final androidPromotionUri =
        _controller.buildAndroidPromotionUri(redirectPath: redirectPath);
    final title = '${_controller.appDisplayName} fica melhor no app';

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Spacer(),
                      IconButton(
                        key: const Key('app_promotion_close_button'),
                        onPressed: _dismiss,
                        style: IconButton.styleFrom(
                          backgroundColor: colorScheme.surfaceContainerHighest,
                          foregroundColor: colorScheme.onSurfaceVariant,
                        ),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
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
                                padding:
                                    const EdgeInsets.fromLTRB(12, 24, 12, 24),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _buildBrandIcon(
                                      context: context,
                                      colorScheme: colorScheme,
                                      iconUrl: iconUrl,
                                    ),
                                    const SizedBox(height: 20),
                                    Text(
                                      title,
                                      key: const Key('app_promotion_title'),
                                      textAlign: TextAlign.center,
                                      style:
                                          theme.textTheme.headlineSmall?.copyWith(
                                            fontWeight: FontWeight.w800,
                                            height: 1.15,
                                          ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Continue no app para destravar as ações e a experiência completa.',
                                      textAlign: TextAlign.center,
                                      style:
                                          theme.textTheme.bodyLarge?.copyWith(
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                    ),
                                    const SizedBox(height: 44),
                                    Center(
                                      child: ConstrainedBox(
                                        constraints:
                                            const BoxConstraints(maxWidth: 300),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            _buildBenefitRow(
                                              context: context,
                                              label:
                                                  'Enviar e aceitar convites',
                                            ),
                                            const SizedBox(height: 14),
                                            _buildBenefitRow(
                                              context: context,
                                              label:
                                                  'Favoritar artistas, locais e eventos',
                                            ),
                                            const SizedBox(height: 14),
                                            _buildBenefitRow(
                                              context: context,
                                              label:
                                                  'Receber lembretes da sua agenda',
                                            ),
                                            const SizedBox(height: 14),
                                            _buildBenefitRow(
                                              context: context,
                                              label:
                                                  'Check-ins e benefícios (em breve)',
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
                        if (storePlatforms.contains(
                          AppPromotionStorePlatform.ios,
                        ))
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
                        if (storePlatforms.contains(
                          AppPromotionStorePlatform.android,
                        )) ...[
                          if (storePlatforms.contains(
                            AppPromotionStorePlatform.ios,
                          ))
                            const SizedBox(height: 12),
                          _StoreBadgeButton(
                            key:
                                const Key('app_promotion_store_badge_android'),
                            onTap: androidPromotionUri == null
                                ? null
                                : () => _launch(
                                      uri: androidPromotionUri,
                                      platform:
                                          AppPromotionStorePlatform.android,
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
                          onPressed: _dismiss,
                          child: const Text('AGORA NÃO'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _launch({
    required Uri uri,
    required AppPromotionStorePlatform platform,
  }) {
    unawaited(
      _controller.launchPromotionUri(
        uri: uri,
        platform: platform,
      ),
    );
  }

  void _dismiss() {
    final router = context.router;
    if (router.canPop()) {
      router.pop();
      return;
    }
    router.replaceAll([const TenantHomeRoute()]);
  }

  Widget _buildBrandIcon({
    required BuildContext context,
    required ColorScheme colorScheme,
    required String? iconUrl,
  }) {
    final iconChild = iconUrl == null
        ? Icon(
            Icons.phone_iphone_rounded,
            size: 40,
            color: colorScheme.onPrimaryContainer,
          )
        : BellugaNetworkImage(
            iconUrl,
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

  Widget _buildBenefitRow({
    required BuildContext context,
    required String label,
  }) {
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

import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/support/route_redirect_path.dart';
import 'package:belluga_now/application/telemetry/web_promotion_telemetry.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AppPromotionDialog extends StatelessWidget {
  const AppPromotionDialog({
    super.key,
    this.title = 'Bóra pro App!',
    this.message =
        'No app você confirma presença, envia convites e destrava a experiência completa.',
    this.buttonLabel = 'Baixe o App para Confirmar',
    this.promotionUri,
  });

  final String title;
  final String message;
  final String buttonLabel;
  final Uri? promotionUri;

  static Future<void> show(
    BuildContext context, {
    String? title,
    String? message,
    String? buttonLabel,
    String? redirectPath,
    String? shareCode,
    Uri? promotionUri,
  }) {
    final resolvedPromotionUri = promotionUri ??
        buildTenantPromotionUri(
          redirectPath: redirectPath,
          shareCode: shareCode,
        );
    return showDialog(
      context: context,
      builder: (context) => AppPromotionDialog(
        title: title ?? 'Bóra pro App!',
        message: message ??
            'No app você confirma presença, envia convites e destrava a experiência completa.',
        buttonLabel: buttonLabel ?? 'Baixe o App para Confirmar',
        promotionUri: resolvedPromotionUri,
      ),
    );
  }

  static Uri? buildTenantPromotionUri({
    String? redirectPath,
    String? shareCode,
  }) =>
      buildTenantPromotionUriFromAppContext(
        redirectPath: redirectPath,
        shareCode: shareCode,
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.rocket_launch, size: 60, color: Colors.blue),
          const SizedBox(height: 20),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => context.router.maybePop(),
          child: const Text('Depois'),
        ),
        FilledButton(
          onPressed: () async {
            final router = context.router;
            final uri = promotionUri ?? buildTenantPromotionUri();
            if (uri == null) {
              router.maybePop();
              return;
            }
            router.maybePop();
            if (uri.path == '/open-app') {
              unawaited(WebPromotionTelemetry.trackOpenAppClick());
            }
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          },
          style: FilledButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
          child: Text(buttonLabel),
        ),
      ],
    );
  }

}

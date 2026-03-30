import 'dart:async';

import 'package:belluga_now/application/router/support/route_redirect_path.dart';
import 'package:belluga_now/domain/repositories/app_data_repository_contract.dart';
import 'package:belluga_now/domain/repositories/telemetry_repository_contract.dart';
import 'package:event_tracker_handler/event_tracker_handler.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
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
  }) {
    final normalizedRedirectPath = redirectPath?.trim();
    final hasRedirectPath =
        normalizedRedirectPath != null && normalizedRedirectPath.isNotEmpty;
    final redirectContextCode = hasRedirectPath
        ? resolveWebPromotionShareCode(
            redirectPath: normalizedRedirectPath,
          )
        : null;
    final trimmedCode = shareCode?.trim();
    final normalizedShareCode =
        (trimmedCode == null || trimmedCode.isEmpty) ? null : trimmedCode;
    final normalizedCode =
        redirectContextCode ?? (hasRedirectPath ? null : normalizedShareCode);
    final targetPath = normalizedCode == null ? '/' : '/invite';

    final appDataRepository = GetIt.I.isRegistered<AppDataRepositoryContract>()
        ? GetIt.I.get<AppDataRepositoryContract>()
        : null;
    final baseUri = appDataRepository?.appData.mainDomainValue.value ??
        Uri.tryParse(Uri.base.origin);
    if (baseUri == null || baseUri.host.trim().isEmpty) {
      return null;
    }

    final targetUri = baseUri.resolve('/open-app');
    final query = <String, String>{
      'path': targetPath,
      'store_channel': 'web',
      if (normalizedCode != null) 'code': normalizedCode,
    };
    return targetUri.replace(
      queryParameters: query.isEmpty ? null : query,
    );
  }

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
          onPressed: () => Navigator.pop(context),
          child: const Text('Depois'),
        ),
        FilledButton(
          onPressed: () async {
            final uri = promotionUri ?? buildTenantPromotionUri();
            if (uri == null) {
              if (context.mounted) {
                Navigator.pop(context);
              }
              return;
            }
            if (uri.path == '/open-app') {
              unawaited(_trackWebPromotionClick(uri));
            }
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
            if (context.mounted) {
              Navigator.pop(context);
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

  static Future<void> _trackWebPromotionClick(Uri uri) async {
    if (!GetIt.I.isRegistered<TelemetryRepositoryContract>()) {
      return;
    }

    final telemetry = GetIt.I.get<TelemetryRepositoryContract>();
    final platformTarget = _resolvePlatformTarget();
    const storeChannel = 'web';
    await telemetry.logEvent(
      EventTrackerEvents.buttonClick,
      eventName: 'web_open_app_clicked',
      properties: <String, dynamic>{
        'store_channel': storeChannel,
        'platform_target': platformTarget,
      },
    );
    await telemetry.logEvent(
      EventTrackerEvents.buttonClick,
      eventName: 'web_install_clicked',
      properties: <String, dynamic>{
        'store_channel': storeChannel,
        'platform_target': platformTarget,
      },
    );
  }

  static String _resolvePlatformTarget() {
    return switch (defaultTargetPlatform) {
      TargetPlatform.iOS => 'ios',
      _ => 'android',
    };
  }
}

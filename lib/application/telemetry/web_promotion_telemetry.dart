import 'package:belluga_now/domain/repositories/telemetry_repository_contract.dart';
import 'package:belluga_now/domain/repositories/value_objects/telemetry_repository_contract_values.dart';
import 'package:event_tracker_handler/event_tracker_handler.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';

final class WebPromotionTelemetry {
  WebPromotionTelemetry._();

  static Future<void> trackOpenAppClick() async {
    if (!GetIt.I.isRegistered<TelemetryRepositoryContract>()) {
      return;
    }

    final telemetry = GetIt.I.get<TelemetryRepositoryContract>();
    final platformTarget = switch (defaultTargetPlatform) {
      TargetPlatform.iOS => 'ios',
      _ => 'android',
    };
    const storeChannel = 'web';
    await telemetry.logEvent(
      EventTrackerEvents.buttonClick,
      eventName: telemetryRepoString('web_open_app_clicked'),
      properties: telemetryRepoMap(<String, dynamic>{
        'store_channel': storeChannel,
        'platform_target': platformTarget,
      }),
    );
    await telemetry.logEvent(
      EventTrackerEvents.buttonClick,
      eventName: telemetryRepoString('web_install_clicked'),
      properties: telemetryRepoMap(<String, dynamic>{
        'store_channel': storeChannel,
        'platform_target': platformTarget,
      }),
    );
  }
}

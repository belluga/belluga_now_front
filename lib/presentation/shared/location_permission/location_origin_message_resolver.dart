import 'package:belluga_now/domain/app_data/home_location_origin_reason.dart';
import 'package:belluga_now/domain/app_data/home_location_origin_settings.dart';

class LocationOriginMessageResolver {
  static String live() {
    return 'Estamos usando sua localização para exibir eventos e lugares próximos a você.';
  }

  static String fixed({
    required HomeLocationOriginReason reason,
    required String appName,
  }) {
    return switch (reason) {
      HomeLocationOriginReason.outsideRange =>
        'Sua localização atual está fora da área atendida pelo $appName. Por isso, a estamos usando uma localização de referência para mostrar resultados mais úteis.',
      HomeLocationOriginReason.unavailable =>
        'Sua localização não está disponível agora. Por isso, estamos usando uma localização de referência para mostrar resultados relevantes.',
      HomeLocationOriginReason.live => live(),
    };
  }

  static String fromSettings({
    required HomeLocationOriginSettings settings,
    required String appName,
  }) {
    if (settings.usesLiveLocation) {
      return live();
    }

    return fixed(
      reason: settings.reason,
      appName: appName,
    );
  }
}

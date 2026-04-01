import 'package:belluga_now/domain/app_data/location_origin_reason.dart';
import 'package:belluga_now/domain/app_data/location_origin_settings.dart';

class LocationOriginMessageResolver {
  static String live() =>
      'Estamos usando sua localização para exibir eventos e lugares próximos a você.';

  static String? transientMessageForReason({
    required LocationOriginReason reason,
    required String appName,
  }) {
    return switch (reason) {
      LocationOriginReason.live => null,
      LocationOriginReason.outsideRange =>
        'Sua localização atual está fora da área atendida pelo $appName. Por isso, usamos uma localização de referência para mostrar o eventos e locais dentro da área de atuação.',
      LocationOriginReason.unavailable =>
        'Sua localização não está disponível, por isso, usamos uma localização de referência para mostrar eventos e locais relevantes.',
      LocationOriginReason.userPreference =>
        'Estamos usando uma localização fixa definida por você nas configurações. Você pode alterar para usar sua localização atual nas configurações.',
    };
  }

  static String detailMessageForReason({
    required LocationOriginReason reason,
    required String appName,
  }) {
    return transientMessageForReason(reason: reason, appName: appName) ??
        live();
  }

  static String fromSettings({
    required LocationOriginSettings settings,
    required String appName,
  }) {
    return detailMessageForReason(
      reason: settings.reason,
      appName: appName,
    );
  }
}

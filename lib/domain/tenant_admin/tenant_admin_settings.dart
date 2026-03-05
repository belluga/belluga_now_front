import 'package:belluga_now/domain/tenant_admin/tenant_admin_media_upload.dart';

class TenantAdminMapDefaultOrigin {
  const TenantAdminMapDefaultOrigin({
    required this.lat,
    required this.lng,
    this.label,
  });

  final double lat;
  final double lng;
  final String? label;

  Map<String, dynamic> toJson() {
    return {
      'lat': lat,
      'lng': lng,
      if (label != null && label!.trim().isNotEmpty) 'label': label!.trim(),
    };
  }
}

class TenantAdminMapUiSettings {
  const TenantAdminMapUiSettings({
    required this.rawMapUi,
    required this.defaultOrigin,
  });

  const TenantAdminMapUiSettings.empty()
      : rawMapUi = const <String, dynamic>{},
        defaultOrigin = null;

  final Map<String, dynamic> rawMapUi;
  final TenantAdminMapDefaultOrigin? defaultOrigin;

  TenantAdminMapUiSettings applyDefaultOrigin(
    TenantAdminMapDefaultOrigin? origin,
  ) {
    final nextRaw = Map<String, dynamic>.from(rawMapUi);
    if (origin == null) {
      nextRaw['default_origin'] = const <String, dynamic>{
        'lat': null,
        'lng': null,
        'label': null,
      };
    } else {
      nextRaw['default_origin'] = origin.toJson();
    }
    return TenantAdminMapUiSettings(
      rawMapUi: Map<String, dynamic>.unmodifiable(nextRaw),
      defaultOrigin: origin,
    );
  }
}

class TenantAdminFirebaseSettings {
  const TenantAdminFirebaseSettings({
    required this.apiKey,
    required this.appId,
    required this.projectId,
    required this.messagingSenderId,
    required this.storageBucket,
  });

  final String apiKey;
  final String appId;
  final String projectId;
  final String messagingSenderId;
  final String storageBucket;

  Map<String, dynamic> toJson() {
    return {
      'apiKey': apiKey,
      'appId': appId,
      'projectId': projectId,
      'messagingSenderId': messagingSenderId,
      'storageBucket': storageBucket,
    };
  }
}

class TenantAdminPushSettings {
  const TenantAdminPushSettings({
    required this.maxTtlDays,
    required this.maxPerMinute,
    required this.maxPerHour,
  });

  final int maxTtlDays;
  final int maxPerMinute;
  final int maxPerHour;

  Map<String, dynamic> toJson() {
    return {
      'max_ttl_days': maxTtlDays,
      'throttles': {
        'max_per_minute': maxPerMinute,
        'max_per_hour': maxPerHour,
      },
    };
  }
}

class TenantAdminTelemetryIntegration {
  const TenantAdminTelemetryIntegration({
    required this.type,
    required this.trackAll,
    required this.events,
    this.token,
    this.url,
    this.extra,
  });

  final String type;
  final bool trackAll;
  final List<String> events;
  final String? token;
  final String? url;
  final Map<String, dynamic>? extra;

  Map<String, dynamic> toUpsertPayload() {
    return {
      'type': type,
      'track_all': trackAll,
      'events': events,
      if (token != null && token!.trim().isNotEmpty) 'token': token!.trim(),
      if (url != null && url!.trim().isNotEmpty) 'url': url!.trim(),
      if (extra != null) ...extra!,
    };
  }
}

class TenantAdminTelemetrySettingsSnapshot {
  const TenantAdminTelemetrySettingsSnapshot({
    required this.integrations,
    required this.availableEvents,
  });

  const TenantAdminTelemetrySettingsSnapshot.empty()
      : integrations = const [],
        availableEvents = const [];

  final List<TenantAdminTelemetryIntegration> integrations;
  final List<String> availableEvents;
}

enum TenantAdminBrandingBrightness {
  light,
  dark;

  String get rawValue => switch (this) {
        TenantAdminBrandingBrightness.light => 'light',
        TenantAdminBrandingBrightness.dark => 'dark',
      };

  static TenantAdminBrandingBrightness fromRaw(String? raw) {
    if (raw?.trim().toLowerCase() == 'dark') {
      return TenantAdminBrandingBrightness.dark;
    }
    return TenantAdminBrandingBrightness.light;
  }
}

class TenantAdminBrandingSettings {
  const TenantAdminBrandingSettings({
    required this.tenantName,
    required this.brightnessDefault,
    required this.primarySeedColor,
    required this.secondarySeedColor,
    this.lightLogoUrl,
    this.darkLogoUrl,
    this.lightIconUrl,
    this.darkIconUrl,
    this.faviconUrl,
    this.pwaIconUrl,
  });

  final String tenantName;
  final TenantAdminBrandingBrightness brightnessDefault;
  final String primarySeedColor;
  final String secondarySeedColor;
  final String? lightLogoUrl;
  final String? darkLogoUrl;
  final String? lightIconUrl;
  final String? darkIconUrl;
  final String? faviconUrl;
  final String? pwaIconUrl;
}

class TenantAdminBrandingUpdateInput {
  const TenantAdminBrandingUpdateInput({
    required this.tenantName,
    required this.brightnessDefault,
    required this.primarySeedColor,
    required this.secondarySeedColor,
    this.lightLogoUpload,
    this.darkLogoUpload,
    this.lightIconUpload,
    this.darkIconUpload,
    this.faviconUpload,
    this.pwaIconUpload,
  });

  final String tenantName;
  final TenantAdminBrandingBrightness brightnessDefault;
  final String primarySeedColor;
  final String secondarySeedColor;
  final TenantAdminMediaUpload? lightLogoUpload;
  final TenantAdminMediaUpload? darkLogoUpload;
  final TenantAdminMediaUpload? lightIconUpload;
  final TenantAdminMediaUpload? darkIconUpload;
  final TenantAdminMediaUpload? faviconUpload;
  final TenantAdminMediaUpload? pwaIconUpload;
}

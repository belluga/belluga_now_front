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

class TenantAdminMapFilterCatalogItem {
  const TenantAdminMapFilterCatalogItem({
    required this.key,
    required this.label,
    this.imageUri,
    this.query = const TenantAdminMapFilterQuery(),
  });

  final String key;
  final String label;
  final String? imageUri;
  final TenantAdminMapFilterQuery query;

  TenantAdminMapFilterCatalogItem copyWith({
    String? key,
    String? label,
    String? imageUri,
    bool clearImageUri = false,
    TenantAdminMapFilterQuery? query,
  }) {
    return TenantAdminMapFilterCatalogItem(
      key: key ?? this.key,
      label: label ?? this.label,
      imageUri: clearImageUri ? null : (imageUri ?? this.imageUri),
      query: query ?? this.query,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'key': key.trim(),
      'label': label.trim(),
      if (imageUri != null && imageUri!.trim().isNotEmpty)
        'image_uri': imageUri!.trim(),
      if (!query.isEmpty) 'query': query.toJson(),
    };
  }
}

enum TenantAdminMapFilterSource {
  accountProfile('account_profile', 'Conta'),
  staticAsset('static_asset', 'Asset'),
  event('event', 'Evento');

  const TenantAdminMapFilterSource(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static TenantAdminMapFilterSource? fromRaw(String? raw) {
    final normalized = raw?.trim().toLowerCase();
    for (final candidate in TenantAdminMapFilterSource.values) {
      if (candidate.apiValue == normalized) {
        return candidate;
      }
    }
    return null;
  }
}

class TenantAdminMapFilterQuery {
  const TenantAdminMapFilterQuery({
    this.source,
    this.types = const <String>[],
    this.taxonomy = const <String>[],
  });

  final TenantAdminMapFilterSource? source;
  final List<String> types;
  final List<String> taxonomy;

  bool get isEmpty =>
      source == null && types.isEmpty && taxonomy.isEmpty;

  TenantAdminMapFilterQuery copyWith({
    TenantAdminMapFilterSource? source,
    List<String>? types,
    List<String>? taxonomy,
    bool clearSource = false,
  }) {
    return TenantAdminMapFilterQuery(
      source: clearSource ? null : (source ?? this.source),
      types: types ?? this.types,
      taxonomy: taxonomy ?? this.taxonomy,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (source != null) 'source': source!.apiValue,
      if (types.isNotEmpty) 'types': types,
      if (taxonomy.isNotEmpty) 'taxonomy': taxonomy,
    };
  }

  static TenantAdminMapFilterQuery fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const TenantAdminMapFilterQuery();
    }

    List<String> _asStringList(dynamic raw) {
      if (raw is! List) {
        return const <String>[];
      }
      return raw
          .map((entry) => entry.toString().trim().toLowerCase())
          .where((entry) => entry.isNotEmpty)
          .toSet()
          .toList(growable: false);
    }

    return TenantAdminMapFilterQuery(
      source: TenantAdminMapFilterSource.fromRaw(json['source']?.toString()),
      types: _asStringList(json['types']),
      taxonomy: _asStringList(json['taxonomy']),
    );
  }
}

class TenantAdminMapFilterRuleCatalog {
  const TenantAdminMapFilterRuleCatalog({
    required this.typesBySource,
    required this.taxonomyTermsBySource,
  });

  const TenantAdminMapFilterRuleCatalog.empty()
      : typesBySource = const <TenantAdminMapFilterSource,
            List<TenantAdminMapFilterTypeOption>>{},
        taxonomyTermsBySource = const <TenantAdminMapFilterSource,
            List<TenantAdminMapFilterTaxonomyTermOption>>{};

  final Map<TenantAdminMapFilterSource, List<TenantAdminMapFilterTypeOption>>
      typesBySource;
  final Map<TenantAdminMapFilterSource,
      List<TenantAdminMapFilterTaxonomyTermOption>> taxonomyTermsBySource;

  bool get isEmpty => typesBySource.isEmpty && taxonomyTermsBySource.isEmpty;

  List<TenantAdminMapFilterTypeOption> typesForSource(
    TenantAdminMapFilterSource source,
  ) {
    return typesBySource[source] ?? const <TenantAdminMapFilterTypeOption>[];
  }

  List<TenantAdminMapFilterTaxonomyTermOption> taxonomyForSource(
    TenantAdminMapFilterSource source,
  ) {
    return taxonomyTermsBySource[source] ??
        const <TenantAdminMapFilterTaxonomyTermOption>[];
  }
}

class TenantAdminMapFilterTypeOption {
  const TenantAdminMapFilterTypeOption({
    required this.slug,
    required this.label,
  });

  final String slug;
  final String label;
}

class TenantAdminMapFilterTaxonomyTermOption {
  const TenantAdminMapFilterTaxonomyTermOption({
    required this.token,
    required this.label,
    required this.taxonomySlug,
    required this.taxonomyLabel,
  });

  final String token;
  final String label;
  final String taxonomySlug;
  final String taxonomyLabel;
}

class TenantAdminMapUiSettings {
  const TenantAdminMapUiSettings({
    required this.rawMapUi,
    required this.defaultOrigin,
    required this.filters,
  });

  const TenantAdminMapUiSettings.empty()
      : rawMapUi = const <String, dynamic>{},
        defaultOrigin = null,
        filters = const <TenantAdminMapFilterCatalogItem>[];

  final Map<String, dynamic> rawMapUi;
  final TenantAdminMapDefaultOrigin? defaultOrigin;
  final List<TenantAdminMapFilterCatalogItem> filters;

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
      filters: List<TenantAdminMapFilterCatalogItem>.unmodifiable(filters),
    );
  }

  TenantAdminMapUiSettings applyFilters(
    List<TenantAdminMapFilterCatalogItem> nextFilters,
  ) {
    final sanitized = nextFilters
        .map(
          (item) => TenantAdminMapFilterCatalogItem(
            key: item.key.trim(),
            label: item.label.trim(),
            imageUri: item.imageUri?.trim().isEmpty ?? true
                ? null
                : item.imageUri?.trim(),
            query: TenantAdminMapFilterQuery(
              source: item.query.source,
              types: item.query.types
                  .map((entry) => entry.trim().toLowerCase())
                  .where((entry) => entry.isNotEmpty)
                  .toSet()
                  .toList(growable: false),
              taxonomy: item.query.taxonomy
                  .map((entry) => entry.trim().toLowerCase())
                  .where((entry) => entry.isNotEmpty)
                  .toSet()
                  .toList(growable: false),
            ),
          ),
        )
        .where((item) => item.key.isNotEmpty && item.label.isNotEmpty)
        .toList(growable: false);

    final nextRaw = Map<String, dynamic>.from(rawMapUi);
    nextRaw['filters'] = sanitized.map((item) => item.toJson()).toList();
    return TenantAdminMapUiSettings(
      rawMapUi: Map<String, dynamic>.unmodifiable(nextRaw),
      defaultOrigin: defaultOrigin,
      filters: List<TenantAdminMapFilterCatalogItem>.unmodifiable(sanitized),
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

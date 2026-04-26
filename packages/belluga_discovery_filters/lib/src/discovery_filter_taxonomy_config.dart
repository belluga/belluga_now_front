part of 'discovery_filter_catalog.dart';

class DiscoveryFilterTaxonomyConfig {
  const DiscoveryFilterTaxonomyConfig({
    required this.taxonomyKey,
    this.labelOverride,
    this.showLabel = true,
    this.selectionMode = DiscoveryFilterSelectionMode.multiple,
  });

  factory DiscoveryFilterTaxonomyConfig.fromJson(
    String taxonomyKey,
    Map<String, Object?> json,
  ) {
    return DiscoveryFilterTaxonomyConfig(
      taxonomyKey: taxonomyKey,
      labelOverride: _readString(json['label']) ??
          _readString(json['label_override']) ??
          _readString(json['title']),
      showLabel: _readBool(json['show_label']) ?? true,
      selectionMode: DiscoveryFilterSelectionModeX.fromWire(
        _readString(json['selection_mode']),
        fallback: DiscoveryFilterSelectionMode.multiple,
      ),
    );
  }

  final String taxonomyKey;
  final String? labelOverride;
  final bool showLabel;
  final DiscoveryFilterSelectionMode selectionMode;

  Map<String, Object?> toJson() => <String, Object?>{
        if (labelOverride != null) 'label_override': labelOverride,
        'show_label': showLabel,
        'selection_mode': selectionMode.wireName,
      };
}

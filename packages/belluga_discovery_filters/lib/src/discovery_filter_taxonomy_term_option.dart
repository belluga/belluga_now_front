part of 'discovery_filter_catalog.dart';

class DiscoveryFilterTaxonomyTermOption {
  const DiscoveryFilterTaxonomyTermOption({
    required this.value,
    required this.label,
  });

  factory DiscoveryFilterTaxonomyTermOption.fromJson(
    Map<String, Object?> json,
  ) {
    return DiscoveryFilterTaxonomyTermOption(
      value: _readString(json['value']) ??
          _readString(json['slug']) ??
          _readString(json['key']) ??
          '',
      label: _readString(json['label']) ??
          _readString(json['name']) ??
          _readString(json['value']) ??
          '',
    );
  }

  final String value;
  final String label;

  bool get isValid => value.trim().isNotEmpty && label.trim().isNotEmpty;

  Map<String, Object?> toJson() => <String, Object?>{
        'value': value,
        'label': label,
      };
}

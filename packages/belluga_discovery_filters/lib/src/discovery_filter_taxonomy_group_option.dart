part of 'discovery_filter_catalog.dart';

class DiscoveryFilterTaxonomyGroupOption {
  const DiscoveryFilterTaxonomyGroupOption({
    required this.key,
    required this.label,
    this.terms = const <DiscoveryFilterTaxonomyTermOption>[],
    this.termsTruncated = false,
    this.termsLimit,
  });

  factory DiscoveryFilterTaxonomyGroupOption.fromJson(
    String fallbackKey,
    Map<String, Object?> json,
  ) {
    return DiscoveryFilterTaxonomyGroupOption(
      key: _readString(json['key']) ??
          _readString(json['slug']) ??
          _readString(json['type']) ??
          fallbackKey,
      label: _readString(json['label']) ??
          _readString(json['name']) ??
          _readString(json['key']) ??
          fallbackKey,
      terms: _readMapList(json['terms'])
          .map(DiscoveryFilterTaxonomyTermOption.fromJson)
          .where((term) => term.isValid)
          .toList(growable: false),
      termsTruncated: _readBool(json['terms_truncated']) ??
          _readBool(json['termsTruncated']) ??
          false,
      termsLimit: _readInt(json['terms_limit']) ?? _readInt(json['termsLimit']),
    );
  }

  final String key;
  final String label;
  final List<DiscoveryFilterTaxonomyTermOption> terms;
  final bool termsTruncated;
  final int? termsLimit;

  bool get isValid => key.trim().isNotEmpty && label.trim().isNotEmpty;

  Map<String, Object?> toJson() => <String, Object?>{
        'key': key,
        'label': label,
        'terms': terms.map((term) => term.toJson()).toList(growable: false),
        'terms_truncated': termsTruncated,
        if (termsLimit != null) 'terms_limit': termsLimit,
      };
}

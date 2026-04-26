part of 'discovery_filter_query_payload.dart';

class DiscoveryFilterTaxonomyQueryEntry {
  const DiscoveryFilterTaxonomyQueryEntry({
    required this.type,
    required this.value,
  });

  final String type;
  final String value;

  Map<String, String> toJson() => <String, String>{
        'type': type,
        'value': value,
      };
}

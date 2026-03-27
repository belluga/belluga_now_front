import 'package:belluga_now/domain/map/value_objects/poi_filter_key_value.dart';

typedef MainFilterOptionMetadataRecord = ({
  PoiFilterKeyValue keyValue,
  Object? value,
});

class MainFilterOptionMetadata {
  MainFilterOptionMetadata({
    Iterable<MainFilterOptionMetadataRecord> records =
        const <MainFilterOptionMetadataRecord>[],
  }) : records = List<MainFilterOptionMetadataRecord>.unmodifiable(records);

  final List<MainFilterOptionMetadataRecord> records;

  Map<String, Object?> get values {
    final payload = <String, Object?>{};
    for (final record in records) {
      payload[record.keyValue.value] = record.value;
    }
    return Map<String, Object?>.unmodifiable(payload);
  }
}

import 'package:belluga_now/domain/map/filters/main_filter_option_metadata_entry.dart';

class MainFilterOptionMetadataEntries {
  MainFilterOptionMetadataEntries() : _value = <MainFilterOptionMetadataEntry>[];

  final List<MainFilterOptionMetadataEntry> _value;

  List<MainFilterOptionMetadataEntry> get value =>
      List<MainFilterOptionMetadataEntry>.unmodifiable(_value);

  void add(MainFilterOptionMetadataEntry entry) {
    _value.add(entry);
  }
}

export 'package:belluga_now/domain/map/filters/main_filter_option_metadata_entries.dart';
export 'package:belluga_now/domain/map/filters/main_filter_option_metadata_entry.dart';

import 'package:belluga_now/domain/map/filters/main_filter_option_metadata_entries.dart';
import 'package:belluga_now/domain/map/filters/main_filter_option_metadata_entry.dart';

class MainFilterOptionMetadata {
  MainFilterOptionMetadata({
    MainFilterOptionMetadataEntries? entries,
  }) : records = List<MainFilterOptionMetadataEntry>.unmodifiable(
         entries?.value ?? <MainFilterOptionMetadataEntry>[],
       );

  final List<MainFilterOptionMetadataEntry> records;
}

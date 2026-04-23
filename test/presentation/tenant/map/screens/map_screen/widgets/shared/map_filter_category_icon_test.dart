import 'package:belluga_now/domain/map/filters/poi_filter_category.dart';
import 'package:belluga_now/domain/map/filters/poi_filter_marker_override.dart';
import 'package:belluga_now/domain/map/value_objects/poi_boolean_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_filter_count_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_filter_image_uri_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_filter_key_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_filter_label_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_hex_color_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_icon_symbol_value.dart';
import 'package:belluga_now/presentation/tenant_public/map/screens/map_screen/widgets/shared/map_filter_category_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'renders marker override icon before legacy filter image',
    (tester) async {
      const imageUri = 'https://tenant.test/media/filter.png';
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: MapFilterCategoryIcon(
              category: _buildCategory(
                imageUri: imageUri,
                overrideMarker: true,
                markerOverride: PoiFilterMarkerOverride.icon(
                  iconValue: _iconValue('music_note'),
                  colorHexValue: _hexValue('#990000'),
                  iconColorHexValue: _hexValue('#FFFFFF'),
                ),
              ),
              isActive: false,
              fallbackIcon: Icons.filter_alt_rounded,
              fallbackColor: Colors.black,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.music_note), findsOneWidget);
      expect(find.byKey(const ValueKey<String>(imageUri)), findsNothing);
    },
  );
}

PoiFilterCategory _buildCategory({
  required String imageUri,
  required bool overrideMarker,
  required PoiFilterMarkerOverride markerOverride,
}) {
  return PoiFilterCategory(
    keyValue: _keyValue('asset_filter'),
    labelValue: _labelValue('Praia'),
    countValue: _countValue(1),
    tagValues: const [],
    imageUriValue: _imageUriValue(imageUri),
    overrideMarkerValue: _boolValue(overrideMarker),
    markerOverride: markerOverride,
  );
}

PoiFilterKeyValue _keyValue(String raw) {
  final value = PoiFilterKeyValue();
  value.parse(raw);
  return value;
}

PoiFilterLabelValue _labelValue(String raw) {
  final value = PoiFilterLabelValue();
  value.parse(raw);
  return value;
}

PoiFilterImageUriValue _imageUriValue(String raw) {
  final value = PoiFilterImageUriValue();
  value.parse(raw);
  return value;
}

PoiFilterCountValue _countValue(int raw) {
  final value = PoiFilterCountValue();
  value.parse(raw.toString());
  return value;
}

PoiBooleanValue _boolValue(bool raw) {
  final value = PoiBooleanValue();
  value.parse(raw.toString());
  return value;
}

PoiIconSymbolValue _iconValue(String raw) {
  final value = PoiIconSymbolValue();
  value.parse(raw);
  return value;
}

PoiHexColorValue _hexValue(String raw) {
  final value = PoiHexColorValue();
  value.parse(raw);
  return value;
}

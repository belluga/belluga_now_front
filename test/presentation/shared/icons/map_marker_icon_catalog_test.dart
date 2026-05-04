import 'dart:convert';
import 'dart:io';

import 'package:belluga_now/application/icons/boora_icons.dart';
import 'package:belluga_now/presentation/shared/icons/map_marker_icon_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fromStorage resolves canonical keys and legacy aliases', () {
    expect(
      MapMarkerIconToken.fromStorage('place'),
      MapMarkerIconToken.local,
    );
    expect(
      MapMarkerIconToken.fromStorage('location_on'),
      MapMarkerIconToken.local,
    );
    expect(
      MapMarkerIconToken.fromStorage('shopping_bag'),
      MapMarkerIconToken.shoppingBag,
    );
    expect(
      MapMarkerIconToken.fromStorage(' CULTURE '),
      MapMarkerIconToken.museum,
    );
    expect(
      MapMarkerIconToken.fromStorage('sorvete'),
      MapMarkerIconToken.iceCream,
    );
    expect(
      MapMarkerIconToken.fromStorage('quiosque'),
      MapMarkerIconToken.kiosk,
    );
    expect(
      MapMarkerIconToken.fromStorage('invitation_outline'),
      MapMarkerIconToken.invitationOutlined,
    );
    expect(
      MapMarkerIconToken.fromStorage('unknown-token'),
      isNull,
    );
  });

  test('catalog exposes every new Boora font icon exactly once', () {
    expect(MapMarkerIconToken.values.length,
        MapMarkerIconToken.booraFontIconCount);
    expect(MapMarkerIconToken.booraFontIconCount, BooraIcons.fontIconCount);
    expect(
      MapMarkerIconToken.values.map((entry) => entry.iconData).toSet().length,
      BooraIcons.fontIconCount,
    );
    expect(
      MapMarkerIconToken.values.every(
        (entry) => entry.iconData.fontFamily == BooraIcons.fontFamily,
      ),
      isTrue,
    );
  });

  test('all uploaded Boora font storage keys are present', () {
    expect(
      MapMarkerIconToken.values.map((entry) => entry.storageKey).toSet(),
      _uploadedBooraIconNames(),
    );
  });

  test('storage keys are unique and non-empty', () {
    final keys =
        MapMarkerIconToken.values.map((entry) => entry.storageKey).toList();
    expect(keys, everyElement(isNotEmpty));
    expect(keys.toSet().length, keys.length);
  });

  test('byGroup returns only entries from the requested group', () {
    final cultureItems = MapMarkerIconToken.byGroup(MapMarkerIconGroup.culture);
    expect(cultureItems, isNotEmpty);
    expect(
      cultureItems.every((entry) => entry.group == MapMarkerIconGroup.culture),
      isTrue,
    );
  });
}

Set<String> _uploadedBooraIconNames() {
  final json = jsonDecode(
    File('assets/fonts/boora_icons_configs/config.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final glyphs = (json['glyphs'] as List<dynamic>).cast<Map<String, dynamic>>();
  return glyphs.map((glyph) => glyph['name'] as String).toSet();
}

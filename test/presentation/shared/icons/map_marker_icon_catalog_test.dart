import 'package:belluga_now/presentation/shared/icons/map_marker_icon_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fromStorage resolves canonical keys and legacy aliases', () {
    expect(
      MapMarkerIconToken.fromStorage('place'),
      MapMarkerIconToken.place,
    );
    expect(
      MapMarkerIconToken.fromStorage('location_on'),
      MapMarkerIconToken.place,
    );
    expect(
      MapMarkerIconToken.fromStorage('shopping_bag'),
      MapMarkerIconToken.shopping,
    );
    expect(
      MapMarkerIconToken.fromStorage(' CULTURE '),
      MapMarkerIconToken.museum,
    );
    expect(
      MapMarkerIconToken.fromStorage('unknown-token'),
      isNull,
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

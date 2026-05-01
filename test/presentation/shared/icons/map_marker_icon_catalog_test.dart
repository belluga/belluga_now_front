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
    const expectedKeys = <String>{
      'clapperboard',
      'running',
      'jubs',
      'group',
      'small-talk',
      'creative-team',
      'presentation',
      'workshop',
      'reading-book',
      'guitar-instrument',
      'live-music',
      'microphone',
      'users-linked',
      'stage',
      'bus-station',
      'market',
      'fireworks',
      'mountains',
      'destination',
      'chef',
      'chef1',
      'united',
      'theater',
      'handshake',
      'open-book',
      'luggage',
      'airplane',
      'coupon',
      'promo',
      'discount',
      'lunch',
      'restaurant',
      'museum',
      'bank',
      'church',
      'musical-note',
      'vinyl',
      'beach-umbrella',
      'hotel',
      'nature',
      'wave',
      'sunset',
      'wave1',
      'paddling',
      'swimmer',
      'drug',
      'pharmacy',
      'first-aid-kit',
      'hospital',
      'grocery-store',
      'shopping-bag',
      'event',
      'local',
      'ticket',
      'ticket1',
    };

    expect(
      MapMarkerIconToken.values.map((entry) => entry.storageKey).toSet(),
      expectedKeys,
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

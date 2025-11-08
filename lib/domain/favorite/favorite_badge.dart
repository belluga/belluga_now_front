import 'package:belluga_now/domain/favorite/value_objects/favorite_badge_icon_value.dart';
import 'package:belluga_now/domain/favorite/value_objects/favorite_badge_font_family_value.dart';
import 'package:belluga_now/domain/favorite/value_objects/favorite_badge_font_package_value.dart';

class FavoriteBadge {
  FavoriteBadge({
    required this.iconValue,
    this.fontFamilyValue,
    this.fontPackageValue,
  });

  final FavoriteBadgeIconValue iconValue;
  final FavoriteBadgeFontFamilyValue? fontFamilyValue;
  final FavoriteBadgeFontPackageValue? fontPackageValue;

  int get codePoint => iconValue.value;

  String? get fontFamily {
    final value = fontFamilyValue?.value;
    if (value == null || value.isEmpty) {
      return null;
    }
    return value;
  }

  String? get fontPackage {
    final value = fontPackageValue?.value;
    if (value == null || value.isEmpty) {
      return null;
    }
    return value;
  }
}

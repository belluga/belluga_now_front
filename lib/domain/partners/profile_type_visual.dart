import 'package:belluga_now/domain/partners/value_objects/profile_type_visual_hex_color_value.dart';
import 'package:belluga_now/domain/partners/value_objects/profile_type_visual_icon_value.dart';
import 'package:belluga_now/domain/partners/value_objects/profile_type_visual_image_url_value.dart';

enum ProfileTypeVisualMode {
  icon,
  image,
}

enum ProfileTypeVisualImageSource {
  avatar,
  cover,
  typeAsset,
}

class ProfileTypeVisual {
  ProfileTypeVisual.icon({
    required this.iconValue,
    required this.colorValue,
    ProfileTypeVisualHexColorValue? iconColorValue,
  })  : mode = ProfileTypeVisualMode.icon,
        iconColorValue = iconColorValue ?? _defaultIconColorValue(),
        imageSource = null,
        imageUrlValue = null;

  ProfileTypeVisual.image({
    required this.imageSource,
    this.imageUrlValue,
  })  : mode = ProfileTypeVisualMode.image,
        iconValue = null,
        colorValue = null,
        iconColorValue = null;

  final ProfileTypeVisualMode mode;
  final ProfileTypeVisualIconValue? iconValue;
  final ProfileTypeVisualHexColorValue? colorValue;
  final ProfileTypeVisualHexColorValue? iconColorValue;
  final ProfileTypeVisualImageSource? imageSource;
  final ProfileTypeVisualImageUrlValue? imageUrlValue;

  String? get icon => iconValue?.value;
  String? get color => colorValue?.value;
  String? get iconColor => iconColorValue?.value;
  String? get imageUrl => imageUrlValue?.nullableValue;

  bool get isIcon => mode == ProfileTypeVisualMode.icon;
  bool get isImage => mode == ProfileTypeVisualMode.image;

  bool get isValid {
    switch (mode) {
      case ProfileTypeVisualMode.icon:
        return iconValue != null &&
            colorValue != null &&
            iconColorValue != null;
      case ProfileTypeVisualMode.image:
        return imageSource != null;
    }
  }

  static ProfileTypeVisualHexColorValue _defaultIconColorValue() {
    final value = ProfileTypeVisualHexColorValue();
    value.parse('#FFFFFF');
    return value;
  }
}

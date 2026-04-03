import 'package:belluga_now/domain/partners/profile_type_definitions.dart';
import 'package:belluga_now/domain/partners/profile_type_capabilities.dart';
import 'package:belluga_now/domain/partners/profile_type_definition.dart';
import 'package:belluga_now/domain/partners/profile_type_visual.dart';
import 'package:belluga_now/domain/partners/value_objects/profile_type_key_value.dart';

typedef ProfileTypeRegistryTypeKey = ProfileTypeKeyValue;

class ProfileTypeRegistry {
  ProfileTypeRegistry({
    required ProfileTypeDefinitions types,
  }) : _types = List<ProfileTypeDefinition>.unmodifiable(types.value);

  final List<ProfileTypeDefinition> _types;

  bool get isEmpty => _types.isEmpty;

  List<ProfileTypeDefinition> get types =>
      List<ProfileTypeDefinition>.unmodifiable(_types);

  bool contains(ProfileTypeKeyValue typeValue) => _byType(typeValue) != null;

  ProfileTypeDefinition? byType(ProfileTypeKeyValue typeValue) =>
      _byType(typeValue);

  bool isFavoritable(ProfileTypeKeyValue typeValue) =>
      _byType(typeValue)?.capabilities.isFavoritable ?? false;

  ProfileTypeCapabilities? capabilitiesFor(ProfileTypeKeyValue typeValue) =>
      _byType(typeValue)?.capabilities;

  bool isEnabledFor(ProfileTypeKeyValue typeValue) => contains(typeValue);

  bool isFavoritableFor(ProfileTypeKeyValue typeValue) =>
      isFavoritable(typeValue);

  String labelForType(ProfileTypeKeyValue typeValue) =>
      _byType(typeValue)?.label ?? typeValue.value;

  ProfileTypeVisual? visualForType(ProfileTypeKeyValue typeValue) =>
      _byType(typeValue)?.visual;

  List<ProfileTypeKeyValue> enabledAccountProfileTypes() =>
      List<ProfileTypeKeyValue>.unmodifiable(
        _types.map((type) => ProfileTypeKeyValue(type.type)),
      );

  ProfileTypeDefinition? _byType(ProfileTypeKeyValue typeValue) {
    for (final type in _types) {
      if (ProfileTypeKeyValue(type.type) == typeValue) {
        return type;
      }
    }
    return null;
  }
}

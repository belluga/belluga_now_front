import 'package:belluga_now/domain/partners/profile_type_capabilities.dart';
import 'package:belluga_now/domain/partners/profile_type_definition.dart';
import 'package:belluga_now/domain/partners/value_objects/profile_type_key_value.dart';

typedef ProfileTypeRegistryTypeKey = ProfileTypeKeyValue;
typedef ProfileTypeRegistryTypeMap
    = Map<ProfileTypeRegistryTypeKey, ProfileTypeDefinition>;

class ProfileTypeRegistry {
  ProfileTypeRegistry({
    required List<ProfileTypeDefinition> types,
  }) : _typesByKey = {
          for (final type in types) ProfileTypeKeyValue(type.type): type,
        };

  final ProfileTypeRegistryTypeMap _typesByKey;

  bool get isEmpty => _typesByKey.isEmpty;

  List<ProfileTypeDefinition> get types =>
      List<ProfileTypeDefinition>.unmodifiable(_typesByKey.values);

  bool contains(ProfileTypeKeyValue typeValue) =>
      _typesByKey.containsKey(typeValue);

  ProfileTypeDefinition? byType(ProfileTypeKeyValue typeValue) =>
      _typesByKey[typeValue];

  bool isFavoritable(ProfileTypeKeyValue typeValue) =>
      _typesByKey[typeValue]?.capabilities.isFavoritable ?? false;

  ProfileTypeCapabilities? capabilitiesFor(ProfileTypeKeyValue typeValue) =>
      _typesByKey[typeValue]?.capabilities;

  bool isEnabledFor(ProfileTypeKeyValue typeValue) => contains(typeValue);

  bool isFavoritableFor(ProfileTypeKeyValue typeValue) =>
      isFavoritable(typeValue);

  String labelForType(ProfileTypeKeyValue typeValue) =>
      _typesByKey[typeValue]?.label ?? typeValue.value;

  List<String> enabledAccountProfileTypes() => List<String>.unmodifiable(
      _typesByKey.keys.map((keyValue) => keyValue.value));
}

import 'package:belluga_now/domain/partners/profile_type_capabilities.dart';
import 'package:belluga_now/domain/partners/profile_type_definition.dart';

class ProfileTypeRegistry {
  ProfileTypeRegistry({
    required List<ProfileTypeDefinition> types,
  }) : _typesByKey = {
          for (final type in types) type.type: type,
        };

  final Map<String, ProfileTypeDefinition> _typesByKey;

  bool get isEmpty => _typesByKey.isEmpty;

  List<ProfileTypeDefinition> get types =>
      List<ProfileTypeDefinition>.unmodifiable(_typesByKey.values);

  bool contains(String type) => _typesByKey.containsKey(type);

  ProfileTypeDefinition? byType(String type) => _typesByKey[type];

  bool isFavoritable(String type) =>
      _typesByKey[type]?.capabilities.isFavoritable ?? false;

  ProfileTypeCapabilities? capabilitiesFor(String type) =>
      _typesByKey[type]?.capabilities;

  bool isEnabledFor(String type) => contains(type);

  bool isFavoritableFor(String type) => isFavoritable(type);

  String labelForType(String type) => _typesByKey[type]?.label ?? type;

  List<String> enabledAccountProfileTypes() =>
      List<String>.unmodifiable(_typesByKey.keys);

  static ProfileTypeRegistry fromJsonList(List<dynamic>? raw) {
    if (raw == null || raw.isEmpty) {
      return ProfileTypeRegistry(types: const []);
    }
    final entries = raw
        .whereType<Map>()
        .map((entry) => ProfileTypeDefinition.fromJson(
              Map<String, dynamic>.from(entry),
            ))
        .where((entry) => entry.type.trim().isNotEmpty)
        .toList(growable: false);
    return ProfileTypeRegistry(types: entries);
  }

}

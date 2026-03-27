import 'package:flutter/material.dart';

enum MapMarkerIconGroup {
  generic(label: 'Geral'),
  gastronomy(label: 'Gastronomia'),
  culture(label: 'Cultura'),
  tourism(label: 'Turismo'),
  services(label: 'Serviços'),
  commerce(label: 'Comércio'),
  partner(label: 'Destaque');

  const MapMarkerIconGroup({
    required this.label,
  });

  final String label;
}

enum MapMarkerIconToken {
  place(
    storageKey: 'place',
    label: 'Local',
    iconData: Icons.place,
    group: MapMarkerIconGroup.generic,
  ),
  event(
    storageKey: 'event',
    label: 'Evento',
    iconData: Icons.event,
    group: MapMarkerIconGroup.generic,
  ),
  activity(
    storageKey: 'activity',
    label: 'Atividade',
    iconData: Icons.local_activity,
    group: MapMarkerIconGroup.generic,
  ),
  restaurant(
    storageKey: 'restaurant',
    label: 'Restaurante',
    iconData: Icons.restaurant,
    group: MapMarkerIconGroup.gastronomy,
  ),
  beach(
    storageKey: 'beach',
    label: 'Praia',
    iconData: Icons.beach_access,
    group: MapMarkerIconGroup.tourism,
  ),
  hotel(
    storageKey: 'hotel',
    label: 'Hospedagem',
    iconData: Icons.hotel,
    group: MapMarkerIconGroup.tourism,
  ),
  museum(
    storageKey: 'museum',
    label: 'Museu',
    iconData: Icons.museum,
    group: MapMarkerIconGroup.culture,
  ),
  hospital(
    storageKey: 'hospital',
    label: 'Saúde',
    iconData: Icons.local_hospital,
    group: MapMarkerIconGroup.services,
  ),
  historic(
    storageKey: 'historic',
    label: 'Histórico',
    iconData: Icons.account_balance,
    group: MapMarkerIconGroup.culture,
  ),
  church(
    storageKey: 'church',
    label: 'Igreja',
    iconData: Icons.church,
    group: MapMarkerIconGroup.culture,
  ),
  nature(
    storageKey: 'nature',
    label: 'Natureza',
    iconData: Icons.park,
    group: MapMarkerIconGroup.tourism,
  ),
  attraction(
    storageKey: 'attraction',
    label: 'Atração',
    iconData: Icons.attractions,
    group: MapMarkerIconGroup.tourism,
  ),
  store(
    storageKey: 'store',
    label: 'Loja',
    iconData: Icons.storefront,
    group: MapMarkerIconGroup.commerce,
  ),
  shopping(
    storageKey: 'shopping',
    label: 'Compras',
    iconData: Icons.shopping_bag,
    group: MapMarkerIconGroup.commerce,
  ),
  music(
    storageKey: 'music',
    label: 'Música',
    iconData: Icons.music_note,
    group: MapMarkerIconGroup.culture,
  ),
  star(
    storageKey: 'star',
    label: 'Destaque',
    iconData: Icons.star,
    group: MapMarkerIconGroup.partner,
  );

  const MapMarkerIconToken({
    required this.storageKey,
    required this.label,
    required this.iconData,
    required this.group,
  });

  // TODO(vnext-map-marker-icon-catalog): Keep existing storage keys immutable.
  // When custom fonts are introduced, only add new enum values/aliases.
  // Never rename or remove existing storage keys to preserve persisted data.
  final String storageKey;
  final String label;
  final IconData iconData;
  final MapMarkerIconGroup group;

  static MapMarkerIconToken? fromStorage(String? raw) {
    final normalized = _normalize(raw);
    if (normalized.isEmpty) {
      return null;
    }
    return _tokenByAlias[normalized];
  }

  static List<MapMarkerIconToken> byGroup(MapMarkerIconGroup group) {
    return values.where((entry) => entry.group == group).toList(growable: false);
  }

  static final Map<String, MapMarkerIconToken> _tokenByAlias =
      <String, MapMarkerIconToken>{
    'place': MapMarkerIconToken.place,
    'location': MapMarkerIconToken.place,
    'locationon': MapMarkerIconToken.place,
    'mappin': MapMarkerIconToken.place,
    'pin': MapMarkerIconToken.place,
    'default': MapMarkerIconToken.place,
    'event': MapMarkerIconToken.event,
    'activity': MapMarkerIconToken.activity,
    'restaurant': MapMarkerIconToken.restaurant,
    'food': MapMarkerIconToken.restaurant,
    'beach': MapMarkerIconToken.beach,
    'hotel': MapMarkerIconToken.hotel,
    'lodging': MapMarkerIconToken.hotel,
    'museum': MapMarkerIconToken.museum,
    'culture': MapMarkerIconToken.museum,
    'hospital': MapMarkerIconToken.hospital,
    'health': MapMarkerIconToken.hospital,
    'historic': MapMarkerIconToken.historic,
    'monument': MapMarkerIconToken.historic,
    'church': MapMarkerIconToken.church,
    'nature': MapMarkerIconToken.nature,
    'park': MapMarkerIconToken.nature,
    'attraction': MapMarkerIconToken.attraction,
    'store': MapMarkerIconToken.store,
    'storefront': MapMarkerIconToken.store,
    'bag': MapMarkerIconToken.shopping,
    'shoppingbag': MapMarkerIconToken.shopping,
    'shopping': MapMarkerIconToken.shopping,
    'music': MapMarkerIconToken.music,
    'star': MapMarkerIconToken.star,
  };

  static String _normalize(String? raw) {
    return (raw ?? '')
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '');
  }
}

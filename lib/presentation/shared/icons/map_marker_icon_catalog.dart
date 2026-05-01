import 'package:belluga_now/application/icons/boora_icons.dart';
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
  clapperboard(
    storageKey: 'clapperboard',
    label: 'Cinema',
    iconData: BooraIcons.clapperboard,
    group: MapMarkerIconGroup.culture,
  ),
  running(
    storageKey: 'running',
    label: 'Corrida',
    iconData: BooraIcons.running,
    group: MapMarkerIconGroup.services,
  ),
  jubs(
    storageKey: 'jubs',
    label: 'Jubs',
    iconData: BooraIcons.jubs,
    group: MapMarkerIconGroup.partner,
  ),
  peopleGroup(
    storageKey: 'group',
    label: 'Grupo',
    iconData: BooraIcons.group,
    group: MapMarkerIconGroup.services,
  ),
  smallTalk(
    storageKey: 'small-talk',
    label: 'Conversa',
    iconData: BooraIcons.smallTalk,
    group: MapMarkerIconGroup.services,
  ),
  creativeTeam(
    storageKey: 'creative-team',
    label: 'Equipe criativa',
    iconData: BooraIcons.creativeTeam,
    group: MapMarkerIconGroup.services,
  ),
  presentation(
    storageKey: 'presentation',
    label: 'Apresentação',
    iconData: BooraIcons.presentation,
    group: MapMarkerIconGroup.services,
  ),
  workshop(
    storageKey: 'workshop',
    label: 'Workshop',
    iconData: BooraIcons.workshop,
    group: MapMarkerIconGroup.services,
  ),
  readingBook(
    storageKey: 'reading-book',
    label: 'Leitura',
    iconData: BooraIcons.readingBook,
    group: MapMarkerIconGroup.culture,
  ),
  guitarInstrument(
    storageKey: 'guitar-instrument',
    label: 'Guitarra',
    iconData: BooraIcons.guitarInstrument,
    group: MapMarkerIconGroup.culture,
  ),
  liveMusic(
    storageKey: 'live-music',
    label: 'Música ao vivo',
    iconData: BooraIcons.liveMusic,
    group: MapMarkerIconGroup.culture,
  ),
  microphone(
    storageKey: 'microphone',
    label: 'Microfone',
    iconData: BooraIcons.microphone,
    group: MapMarkerIconGroup.culture,
  ),
  usersLinked(
    storageKey: 'users-linked',
    label: 'Pessoas conectadas',
    iconData: BooraIcons.usersLinked,
    group: MapMarkerIconGroup.services,
  ),
  stage(
    storageKey: 'stage',
    label: 'Palco',
    iconData: BooraIcons.stage,
    group: MapMarkerIconGroup.culture,
  ),
  busStation(
    storageKey: 'bus-station',
    label: 'Rodoviária',
    iconData: BooraIcons.busStation,
    group: MapMarkerIconGroup.services,
  ),
  market(
    storageKey: 'market',
    label: 'Mercado',
    iconData: BooraIcons.market,
    group: MapMarkerIconGroup.commerce,
  ),
  kiosk(
    storageKey: 'kiosk',
    label: 'Quiosque',
    iconData: BooraIcons.kiosk,
    group: MapMarkerIconGroup.commerce,
  ),
  fireworks(
    storageKey: 'fireworks',
    label: 'Fogos',
    iconData: BooraIcons.fireworks,
    group: MapMarkerIconGroup.tourism,
  ),
  mountains(
    storageKey: 'mountains',
    label: 'Montanhas',
    iconData: BooraIcons.mountains,
    group: MapMarkerIconGroup.tourism,
  ),
  destination(
    storageKey: 'destination',
    label: 'Destino',
    iconData: BooraIcons.destination,
    group: MapMarkerIconGroup.generic,
  ),
  chef(
    storageKey: 'chef',
    label: 'Chef',
    iconData: BooraIcons.chef,
    group: MapMarkerIconGroup.gastronomy,
  ),
  chef1(
    storageKey: 'chef1',
    label: 'Chef alternativo',
    iconData: BooraIcons.chef1,
    group: MapMarkerIconGroup.gastronomy,
  ),
  united(
    storageKey: 'united',
    label: 'Comunidade',
    iconData: BooraIcons.united,
    group: MapMarkerIconGroup.services,
  ),
  theater(
    storageKey: 'theater',
    label: 'Teatro',
    iconData: BooraIcons.theater,
    group: MapMarkerIconGroup.culture,
  ),
  handshake(
    storageKey: 'handshake',
    label: 'Parceria',
    iconData: BooraIcons.handshake,
    group: MapMarkerIconGroup.services,
  ),
  openBook(
    storageKey: 'open-book',
    label: 'Livro aberto',
    iconData: BooraIcons.openBook,
    group: MapMarkerIconGroup.culture,
  ),
  luggage(
    storageKey: 'luggage',
    label: 'Bagagem',
    iconData: BooraIcons.luggage,
    group: MapMarkerIconGroup.tourism,
  ),
  airplane(
    storageKey: 'airplane',
    label: 'Avião',
    iconData: BooraIcons.airplane,
    group: MapMarkerIconGroup.tourism,
  ),
  coupon(
    storageKey: 'coupon',
    label: 'Cupom',
    iconData: BooraIcons.coupon,
    group: MapMarkerIconGroup.partner,
  ),
  promo(
    storageKey: 'promo',
    label: 'Promoção',
    iconData: BooraIcons.promo,
    group: MapMarkerIconGroup.partner,
  ),
  discount(
    storageKey: 'discount',
    label: 'Desconto',
    iconData: BooraIcons.discount,
    group: MapMarkerIconGroup.partner,
  ),
  lunch(
    storageKey: 'lunch',
    label: 'Almoço',
    iconData: BooraIcons.lunch,
    group: MapMarkerIconGroup.gastronomy,
  ),
  iceCream(
    storageKey: 'ice-cream',
    label: 'Sorvete',
    iconData: BooraIcons.iceCream,
    group: MapMarkerIconGroup.gastronomy,
  ),
  restaurant(
    storageKey: 'restaurant',
    label: 'Restaurante',
    iconData: BooraIcons.restaurant,
    group: MapMarkerIconGroup.gastronomy,
  ),
  museum(
    storageKey: 'museum',
    label: 'Museu',
    iconData: BooraIcons.museum,
    group: MapMarkerIconGroup.culture,
  ),
  bank(
    storageKey: 'bank',
    label: 'Banco',
    iconData: BooraIcons.bank,
    group: MapMarkerIconGroup.commerce,
  ),
  church(
    storageKey: 'church',
    label: 'Igreja',
    iconData: BooraIcons.church,
    group: MapMarkerIconGroup.culture,
  ),
  musicalNote(
    storageKey: 'musical-note',
    label: 'Nota musical',
    iconData: BooraIcons.musicalNote,
    group: MapMarkerIconGroup.culture,
  ),
  vinyl(
    storageKey: 'vinyl',
    label: 'Vinil',
    iconData: BooraIcons.vinyl,
    group: MapMarkerIconGroup.culture,
  ),
  beachUmbrella(
    storageKey: 'beach-umbrella',
    label: 'Praia',
    iconData: BooraIcons.beachUmbrella,
    group: MapMarkerIconGroup.tourism,
  ),
  hotel(
    storageKey: 'hotel',
    label: 'Hospedagem',
    iconData: BooraIcons.hotel,
    group: MapMarkerIconGroup.tourism,
  ),
  nature(
    storageKey: 'nature',
    label: 'Natureza',
    iconData: BooraIcons.nature,
    group: MapMarkerIconGroup.tourism,
  ),
  wave(
    storageKey: 'wave',
    label: 'Onda',
    iconData: BooraIcons.wave,
    group: MapMarkerIconGroup.tourism,
  ),
  sunset(
    storageKey: 'sunset',
    label: 'Pôr do sol',
    iconData: BooraIcons.sunset,
    group: MapMarkerIconGroup.tourism,
  ),
  wave1(
    storageKey: 'wave1',
    label: 'Onda alternativa',
    iconData: BooraIcons.wave1,
    group: MapMarkerIconGroup.tourism,
  ),
  paddling(
    storageKey: 'paddling',
    label: 'Remo',
    iconData: BooraIcons.paddling,
    group: MapMarkerIconGroup.tourism,
  ),
  swimmer(
    storageKey: 'swimmer',
    label: 'Natação',
    iconData: BooraIcons.swimmer,
    group: MapMarkerIconGroup.tourism,
  ),
  drug(
    storageKey: 'drug',
    label: 'Medicamento',
    iconData: BooraIcons.drug,
    group: MapMarkerIconGroup.services,
  ),
  pharmacy(
    storageKey: 'pharmacy',
    label: 'Farmácia',
    iconData: BooraIcons.pharmacy,
    group: MapMarkerIconGroup.services,
  ),
  firstAidKit(
    storageKey: 'first-aid-kit',
    label: 'Primeiros socorros',
    iconData: BooraIcons.firstAidKit,
    group: MapMarkerIconGroup.services,
  ),
  hospital(
    storageKey: 'hospital',
    label: 'Hospital',
    iconData: BooraIcons.hospital,
    group: MapMarkerIconGroup.services,
  ),
  groceryStore(
    storageKey: 'grocery-store',
    label: 'Mercearia',
    iconData: BooraIcons.groceryStore,
    group: MapMarkerIconGroup.commerce,
  ),
  shoppingBag(
    storageKey: 'shopping-bag',
    label: 'Compras',
    iconData: BooraIcons.shoppingBag,
    group: MapMarkerIconGroup.commerce,
  ),
  event(
    storageKey: 'event',
    label: 'Evento',
    iconData: BooraIcons.event,
    group: MapMarkerIconGroup.generic,
  ),
  local(
    storageKey: 'local',
    label: 'Local',
    iconData: BooraIcons.local,
    group: MapMarkerIconGroup.generic,
  ),
  ticket(
    storageKey: 'ticket',
    label: 'Ingresso',
    iconData: BooraIcons.ticket,
    group: MapMarkerIconGroup.generic,
  ),
  ticket1(
    storageKey: 'ticket1',
    label: 'Ingresso alternativo',
    iconData: BooraIcons.ticket1,
    group: MapMarkerIconGroup.generic,
  );

  const MapMarkerIconToken({
    required this.storageKey,
    required this.label,
    required this.iconData,
    required this.group,
  });

  static const int booraFontIconCount = BooraIcons.fontIconCount;

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
    return values
        .where((entry) => entry.group == group)
        .toList(growable: false);
  }

  static final Map<String, MapMarkerIconToken> _tokenByAlias =
      <String, MapMarkerIconToken>{
    for (final token in MapMarkerIconToken.values)
      _normalize(token.storageKey): token,
    'place': MapMarkerIconToken.local,
    'location': MapMarkerIconToken.local,
    'locationon': MapMarkerIconToken.local,
    'mappin': MapMarkerIconToken.local,
    'pin': MapMarkerIconToken.local,
    'default': MapMarkerIconToken.local,
    'activity': MapMarkerIconToken.event,
    'food': MapMarkerIconToken.restaurant,
    'beach': MapMarkerIconToken.beachUmbrella,
    'lodging': MapMarkerIconToken.hotel,
    'culture': MapMarkerIconToken.museum,
    'health': MapMarkerIconToken.hospital,
    'historic': MapMarkerIconToken.museum,
    'monument': MapMarkerIconToken.museum,
    'park': MapMarkerIconToken.nature,
    'attraction': MapMarkerIconToken.destination,
    'store': MapMarkerIconToken.market,
    'storefront': MapMarkerIconToken.market,
    'quiosque': MapMarkerIconToken.kiosk,
    'kiosk': MapMarkerIconToken.kiosk,
    'bag': MapMarkerIconToken.shoppingBag,
    'shopping': MapMarkerIconToken.shoppingBag,
    'icecream': MapMarkerIconToken.iceCream,
    'sorvete': MapMarkerIconToken.iceCream,
    'music': MapMarkerIconToken.musicalNote,
    'musicnote': MapMarkerIconToken.musicalNote,
    'audiotrack': MapMarkerIconToken.musicalNote,
    'star': MapMarkerIconToken.promo,
  };

  static String _normalize(String? raw) {
    return (raw ?? '')
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '');
  }
}

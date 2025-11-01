part of 'city_map_screen.dart';

enum PoiCategory {
  restaurant,
  health,
  monument,
  church,
  culture,
  nature,
}

extension on PoiCategory {
  IconData get icon {
    switch (this) {
      case PoiCategory.restaurant:
        return Icons.restaurant;
      case PoiCategory.health:
        return Icons.local_hospital;
      case PoiCategory.monument:
        return Icons.account_balance;
      case PoiCategory.church:
        return Icons.church;
      case PoiCategory.culture:
        return Icons.museum;
      case PoiCategory.nature:
        return Icons.park;
    }
  }

  Color get color {
    switch (this) {
      case PoiCategory.restaurant:
        return const Color(0xFFE15A3C);
      case PoiCategory.health:
        return const Color(0xFF2E7D32);
      case PoiCategory.monument:
        return const Color(0xFF3949AB);
      case PoiCategory.church:
        return const Color(0xFF6D4C41);
      case PoiCategory.culture:
        return const Color(0xFF8E24AA);
      case PoiCategory.nature:
        return const Color(0xFF00897B);
    }
  }

  Color get selectedColor => color.withOpacity(0.95);

  String get label {
    switch (this) {
      case PoiCategory.restaurant:
        return 'Restaurante';
      case PoiCategory.health:
        return 'Hospital';
      case PoiCategory.monument:
        return 'Ponto histórico';
      case PoiCategory.church:
        return 'Igreja';
      case PoiCategory.culture:
        return 'Cultura';
      case PoiCategory.nature:
        return 'Natureza';
    }
  }
}

class CityPoi {
  const CityPoi({
    required this.name,
    required this.description,
    required this.address,
    required this.category,
    required this.coordinate,
  });

  final String name;
  final String description;
  final String address;
  final PoiCategory category;
  final LatLng coordinate;
}

class CityPoiData {
  static final CityPoiData _singleton = CityPoiData._();

  CityPoiData._();

  static List<CityPoi> get points => _singleton._points;

  static LatLng get defaultCenter => _singleton._defaultCenter;

  final LatLng _defaultCenter = const LatLng(-20.673067, -40.498383);

  final List<CityPoi> _points = const [
    CityPoi(
      name: 'Praia do Morro',
      description:
          'Principal praia urbana de Guarapari, com extensa orla, ciclovia e quiosques animados.',
      address: 'Av. Beira Mar, Praia do Morro',
      category: PoiCategory.nature,
      coordinate: LatLng(-20.666407, -40.496702),
    ),
    CityPoi(
      name: 'Radium Hotel',
      description:
          'Construção histórica de 1953, um ícone da arte déco local hoje utilizado para eventos culturais.',
      address: 'Av. Beira Mar, Centro',
      category: PoiCategory.monument,
      coordinate: LatLng(-20.670006, -40.502488),
    ),
    CityPoi(
      name: 'Igreja de Nossa Senhora da Conceição',
      description:
          'Pequena igreja colonial datada do século XVI, um dos pontos religiosos mais antigos da cidade.',
      address: 'Rua Monsenhor Machado, Centro',
      category: PoiCategory.church,
      coordinate: LatLng(-20.673749, -40.505046),
    ),
    CityPoi(
      name: 'Mercado Municipal',
      description:
          'Espaço cultural com feiras, artesanato e gastronomia capixaba, ponto de encontro dos moradores.',
      address: 'Rua Dr. Roberto Calmon, Centro',
      category: PoiCategory.culture,
      coordinate: LatLng(-20.676246, -40.497629),
    ),
    CityPoi(
      name: 'Hospital Materno Infantil Francisco de Assis',
      description:
          'Unidade de referência para atendimento materno-infantil e emergências na região.',
      address: 'Rua Simplício Rodrigues, Centro',
      category: PoiCategory.health,
      coordinate: LatLng(-20.675487, -40.497258),
    ),
    CityPoi(
      name: 'Restaurante Cantinho do Curuca',
      description:
          'Tradicional restaurante especializado em moqueca capixaba e frutos do mar locais.',
      address: 'Av. Antônio Laborda, 400 - Muquiçaba',
      category: PoiCategory.restaurant,
      coordinate: LatLng(-20.659795, -40.498571),
    ),
    CityPoi(
      name: 'Parque Municipal Morro da Pescaria',
      description:
          'Área de preservação ambiental com trilhas e mirantes, acesso à Praia do Ermitão.',
      address: 'Praia do Morro',
      category: PoiCategory.nature,
      coordinate: LatLng(-20.662513, -40.485286),
    ),
    CityPoi(
      name: 'Complexo Esportivo Arena Unimed',
      description:
          'Espaço multiuso com quadras, atividades esportivas e eventos culturais.',
      address: 'Av. Gov. Jones dos Santos Neves, 1190 - Muquiçaba',
      category: PoiCategory.culture,
      coordinate: LatLng(-20.658421, -40.496217),
    ),
  ];
}

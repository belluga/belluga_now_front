import 'package:belluga_now/domain/map/city_poi_category.dart';
import 'package:belluga_now/infrastructure/services/dal/dto/map/city_poi_dto.dart';

class CityPoiDataSource {
  const CityPoiDataSource();

  List<CityPoiDTO> fetchPoints() {
    return const [
      CityPoiDTO(
        id: 'poi-praia-do-morro',
        name: 'Praia do Morro',
        description:
            'Principal praia urbana de Guarapari, com extensa orla, ciclovia e quiosques animados.',
        address: 'Av. Beira Mar, Praia do Morro',
        category: CityPoiCategory.nature,
        latitude: -20.666407,
        longitude: -40.496702,
      ),
      CityPoiDTO(
        id: 'poi-radium-hotel',
        name: 'Radium Hotel',
        description:
            'Construção histórica de 1953, hoje espaço para eventos culturais da cidade.',
        address: 'Av. Beira Mar, Centro',
        category: CityPoiCategory.monument,
        latitude: -20.670006,
        longitude: -40.502488,
      ),
      CityPoiDTO(
        id: 'poi-igreja-conceicao',
        name: 'Igreja de Nossa Senhora da Conceição',
        description:
            'Igreja colonial do século XVI, um dos pontos religiosos mais antigos da região.',
        address: 'Rua Monsenhor Machado, Centro',
        category: CityPoiCategory.church,
        latitude: -20.673749,
        longitude: -40.505046,
      ),
      CityPoiDTO(
        id: 'poi-mercado-municipal',
        name: 'Mercado Municipal',
        description:
            'Feiras, artesanato e gastronomia capixaba em um espaço cultural no coração da cidade.',
        address: 'Rua Dr. Roberto Calmon, Centro',
        category: CityPoiCategory.culture,
        latitude: -20.676246,
        longitude: -40.497629,
      ),
      CityPoiDTO(
        id: 'poi-hospital-francisco-assis',
        name: 'Hospital Materno Infantil Francisco de Assis',
        description:
            'Unidade de referência para atendimento materno-infantil e emergências.',
        address: 'Rua Simplício Rodrigues, Centro',
        category: CityPoiCategory.health,
        latitude: -20.675487,
        longitude: -40.497258,
      ),
      CityPoiDTO(
        id: 'poi-cantinho-curuca',
        name: 'Restaurante Cantinho do Curuca',
        description:
            'Tradição em moquecas e frutos do mar frescos para uma culinária 100% capixaba.',
        address: 'Av. Antônio Laborda, 400 - Muquiçaba',
        category: CityPoiCategory.restaurant,
        latitude: -20.659795,
        longitude: -40.498571,
      ),
      CityPoiDTO(
        id: 'poi-morro-pescaria',
        name: 'Parque Municipal Morro da Pescaria',
        description:
            'Área de preservação com trilhas, mirantes e acesso à Praia do Ermitão.',
        address: 'Praia do Morro',
        category: CityPoiCategory.nature,
        latitude: -20.662513,
        longitude: -40.485286,
      ),
      CityPoiDTO(
        id: 'poi-arena-unimed',
        name: 'Arena Unimed',
        description:
            'Complexo esportivo multiuso com programação de eventos e atividades ao ar livre.',
        address: 'Av. Gov. Jones dos Santos Neves, 1190 - Muquiçaba',
        category: CityPoiCategory.culture,
        latitude: -20.658421,
        longitude: -40.496217,
      ),
    ];
  }
}

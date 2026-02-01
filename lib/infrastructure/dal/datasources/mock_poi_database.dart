import 'package:belluga_now/domain/map/city_poi_category.dart';
import 'package:belluga_now/domain/map/filters/main_filter_option.dart';
import 'package:belluga_now/domain/map/filters/poi_filter_options.dart';
import 'package:belluga_now/domain/map/map_region_definition.dart';
import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';
import 'package:belluga_now/domain/map/value_objects/latitude_value.dart';
import 'package:belluga_now/domain/map/value_objects/longitude_value.dart';
import 'package:belluga_now/domain/map/value_objects/map_region_id_value.dart';
import 'package:belluga_now/domain/map/value_objects/map_region_label_value.dart';
import 'package:belluga_now/domain/map/value_objects/map_zoom_value.dart';
import 'package:belluga_now/domain/map/queries/poi_query.dart';
import 'package:belluga_now/infrastructure/dal/datasources/pois_google_data.dart';
import 'package:belluga_now/infrastructure/dal/dto/map/city_poi_dto.dart';

class MockPoiDatabase {
  const MockPoiDatabase();

  static final List<CityPoiDTO> _rawPois = List.unmodifiable(<CityPoiDTO>[
    CityPoiDTO(
      id: 'poi-sponsor-kidelicia-loja-central',
      name: 'Kidelícia Sorvetes - Loja Central',
      description:
          'Patrocinador oficial Belluga Now — sorvetes artesanais e ponto de encontro.',
      address:
          'Praça Philomeno Pereira Ribeiro, 282 - Muquiçaba, Guarapari - ES',
      category: CityPoiCategory.sponsor,
      latitude: -20.66220228691961,
      longitude: -40.498375644182275,
      assetPath: 'assets/images/kidelicia_logo.png',
      priority: 100,
      tags: ['sponsor', 'sorvetes'],
    ),
    CityPoiDTO(
      id: 'poi-event-luau-praia-do-morro',
      name: 'Luau Praia do Morro',
      description: 'Apresentação musical ao vivo na areia da Praia do Morro.',
      address: 'Praia do Morro, Guarapari',
      category: CityPoiCategory.culture,
      latitude: -20.6629,
      longitude: -40.4958,
      priority: 90,
      tags: ['evento', 'musica', 'agora'],
    ),
    CityPoiDTO(
      id: 'poi-event-feira-artesanal',
      name: 'Feira Artesanal da Orla',
      description: 'Feira cultural com artistas locais e gastronomia típica.',
      address: 'Orla da Praia das Castanheiras, Centro, Guarapari',
      category: CityPoiCategory.culture,
      latitude: -20.6715,
      longitude: -40.4996,
      priority: 80,
      tags: ['evento', 'cultura'],
    ),
    CityPoiDTO(
      id: 'poi-restaurant-american-grill',
      name: 'American Grill',
      description: 'Regional',
      address: 'Guarapari',
      category: CityPoiCategory.restaurant,
      latitude: -20.6600241,
      longitude: -40.502093,
      tags: ['steakhouse', 'grill'],
    ),
    CityPoiDTO(
      id: 'poi-restaurant-acaizeiro',
      name: 'Açaizeiro',
      description: 'Sabores locais e pratos da casa.',
      address: 'Guarapari',
      category: CityPoiCategory.restaurant,
      latitude: -20.651817,
      longitude: -40.4793957,
      tags: ['açai', 'sobremesa'],
    ),
    const CityPoiDTO(
      id: 'poi-restaurant-barraca-do-marcelo',
      name: 'Barraca do Marcelo',
      description:
          'Regional, Petiscos, Bolinho De Aipim De Meaípe, Seafood, Fish, Brazilian, Fries',
      address: 'Meaípe, Guarapari',
      category: CityPoiCategory.restaurant,
      latitude: -20.7381371,
      longitude: -40.5430268,
      tags: ['seafood', 'moqueca', 'petiscos'],
    ),
    CityPoiDTO(
      id: 'poi-restaurant-bella-grill',
      name: 'Bella Grill',
      description: 'Sabores locais e pratos da casa.',
      address: 'Guarapari',
      category: CityPoiCategory.restaurant,
      latitude: -20.6593588,
      longitude: -40.4976746,
      tags: ['churrasco'],
    ),
    const CityPoiDTO(
      id: 'poi-restaurant-alfredo-adega-restaurante',
      name: 'Adega Restaurante',
      description: 'Restaurante em Alfredo Chaves.',
      address: 'Matilde, Alfredo Chaves - ES',
      category: CityPoiCategory.restaurant,
      latitude: -20.555612,
      longitude: -40.816068,
      tags: ['restaurante', 'alfredo chaves', 'matilde'],
    ),
    const CityPoiDTO(
      id: 'poi-restaurant-alfredo-restaurante-prainha',
      name: 'Restaurante Prainha',
      description: 'Restaurante em Alfredo Chaves.',
      address: 'Matilde, Alfredo Chaves - ES',
      category: CityPoiCategory.restaurant,
      latitude: -20.556303,
      longitude: -40.81689,
      tags: ['restaurante', 'alfredo chaves', 'matilde'],
    ),
    const CityPoiDTO(
      id: 'poi-restaurant-alfredo-restaurante-boldrini',
      name: 'Restaurante Boldrini',
      description: 'Restaurante em Alfredo Chaves.',
      address: 'Centro, Alfredo Chaves - ES',
      category: CityPoiCategory.restaurant,
      latitude: -20.634608,
      longitude: -40.751046,
      tags: ['restaurante', 'alfredo chaves', 'centro'],
    ),
    const CityPoiDTO(
      id: 'poi-restaurant-alfredo-padaria-confeitaria-boldrini',
      name: 'Padaria e Confeitaria Boldrini',
      description: 'Padaria e confeitaria em Alfredo Chaves.',
      address: 'Centro, Alfredo Chaves - ES',
      category: CityPoiCategory.restaurant,
      latitude: -20.634671,
      longitude: -40.751134,
      tags: ['padaria', 'café', 'alfredo chaves', 'centro'],
    ),
    const CityPoiDTO(
      id: 'poi-restaurant-alfredo-padaria-ki-pao',
      name: 'Padaria Ki-pão',
      description: 'Padaria em Alfredo Chaves.',
      address: 'Centro, Alfredo Chaves - ES',
      category: CityPoiCategory.restaurant,
      latitude: -20.634985,
      longitude: -40.750269,
      tags: ['padaria', 'café', 'alfredo chaves', 'centro'],
    ),
    const CityPoiDTO(
      id: 'poi-restaurant-alfredo-sitio-recanto-das-videiras',
      name: 'Sitio Recanto das Videiras',
      description: 'Restaurante em Alfredo Chaves.',
      address: 'Alfredo Chaves - ES',
      category: CityPoiCategory.restaurant,
      latitude: -20.5524902,
      longitude: -40.8487666,
      tags: ['restaurante', 'alfredo chaves'],
    ),
    CityPoiDTO(
      id: 'poi-restaurant-benfica',
      name: 'Benfica',
      description: 'Capixaba',
      address: 'Rua Henrique Coutinho, 16 lj 6, Centro, Guarapari',
      category: CityPoiCategory.restaurant,
      latitude: -20.6708241,
      longitude: -40.496421,
      tags: ['capixaba', 'regional'],
    ),
    CityPoiDTO(
      id: 'poi-restaurant-bistro-pousada-orchidas',
      name: 'Bistro & Pousada Orchidas',
      description: 'Sabores locais e pratos da casa.',
      address: 'Guarapari',
      category: CityPoiCategory.restaurant,
      latitude: -20.7398642,
      longitude: -40.5571611,
    ),
    CityPoiDTO(
      id: 'poi-restaurant-bistro-crepusculo',
      name: 'Bistro Crepusculo',
      description: 'Sabores locais e pratos da casa.',
      address: 'Rua Getúlio Vargas, Guarapari',
      category: CityPoiCategory.restaurant,
      latitude: -20.6689486,
      longitude: -40.497165,
    ),
    CityPoiDTO(
      id: 'poi-restaurant-bistro-sal-e-tal',
      name: 'Bistro Sal e Tal',
      description: 'Sabores locais e pratos da casa.',
      address: 'Guarapari',
      category: CityPoiCategory.restaurant,
      latitude: -20.7217392,
      longitude: -40.5241274,
    ),
    CityPoiDTO(
      id: 'poi-restaurant-bolhina-s',
      name: 'Bolhina\'s',
      description: 'Pizza, Mineira',
      address: 'Guarapari',
      category: CityPoiCategory.restaurant,
      latitude: -20.6719096,
      longitude: -40.4976207,
    ),
    CityPoiDTO(
      id: 'poi-restaurant-bolinhas-bar-e-restaurante',
      name: 'Bolinhas Bar e Restaurante',
      description: 'Sabores locais e pratos da casa.',
      address: 'Avenida Desembargador Laurival de Almeida, Centro, Guarapari',
      category: CityPoiCategory.restaurant,
      latitude: -20.6739006,
      longitude: -40.4980227,
    ),
    CityPoiDTO(
      id: 'poi-restaurant-bom-preco',
      name: 'Bom Preço',
      description: 'Sabores locais e pratos da casa.',
      address: 'Guarapari',
      category: CityPoiCategory.restaurant,
      latitude: -20.8084686,
      longitude: -40.6424138,
    ),
    CityPoiDTO(
      id: 'poi-restaurant-box-mineiro',
      name: 'Box Mineiro',
      description: 'Regional',
      address: 'Rua Henrique Coutinho, 34, Guarapari',
      category: CityPoiCategory.restaurant,
      latitude: -20.6703232,
      longitude: -40.4965388,
    ),
    CityPoiDTO(
      id: 'poi-restaurant-brasileirinha',
      name: 'Brasileirinha',
      description: 'Regional',
      address: 'Guarapari',
      category: CityPoiCategory.restaurant,
      latitude: -20.670596,
      longitude: -40.4972975,
    ),
    CityPoiDTO(
      id: 'poi-restaurant-buffalo-grill',
      name: 'Buffalo Grill',
      description: 'Steak House',
      address: 'Avenida Praiana, Guarapari',
      category: CityPoiCategory.restaurant,
      latitude: -20.6519896,
      longitude: -40.486194,
    ),
    CityPoiDTO(
      id: 'poi-restaurant-butiquim',
      name: 'Butiquim',
      description: 'Sabores locais e pratos da casa.',
      address: 'Guarapari',
      category: CityPoiCategory.restaurant,
      latitude: -20.6544603,
      longitude: -40.4945407,
    ),
    CityPoiDTO(
      id: 'poi-restaurant-caldo-prosa',
      name: 'Caldo & Prosa',
      description: 'Sabores locais e pratos da casa.',
      address: 'Guarapari',
      category: CityPoiCategory.restaurant,
      latitude: -20.7353754,
      longitude: -40.5420376,
    ),
    CityPoiDTO(
      id: 'poi-restaurant-canecao-restaurante',
      name: 'Canecão Restaurante',
      description: 'Sabores locais e pratos da casa.',
      address: 'Avenida Maria de Lourdes Carvalho Dantas, Guarapari',
      category: CityPoiCategory.restaurant,
      latitude: -20.6518373,
      longitude: -40.4860386,
    ),
    CityPoiDTO(
      id: 'poi-restaurant-cantinho-de-curuca',
      name: 'Cantinho de Curuca',
      description: 'Capixaba',
      address: 'Guarapari',
      category: CityPoiCategory.restaurant,
      latitude: -20.7379051,
      longitude: -40.5386139,
    ),
    CityPoiDTO(
      id: 'poi-restaurant-caranguelua',
      name: 'Caranguelua',
      description: 'Regional',
      address: 'Guarapari',
      category: CityPoiCategory.restaurant,
      latitude: -20.6711982,
      longitude: -40.4952968,
    ),
    CityPoiDTO(
      id: 'poi-restaurant-casa-portuguesa',
      name: 'Casa Portuguêsa',
      description: 'Sabores locais e pratos da casa.',
      address: 'Guarapari',
      category: CityPoiCategory.restaurant,
      latitude: -20.7225113,
      longitude: -40.5250341,
    ),
    CityPoiDTO(
      id: 'poi-restaurant-chef-s',
      name: 'Chef\'s',
      description: 'Barbecue',
      address: 'Avenida Paris, 60, Guarapari',
      category: CityPoiCategory.restaurant,
      latitude: -20.6512394,
      longitude: -40.4790071,
    ),
    CityPoiDTO(
      id: 'poi-restaurant-chopperia-informal',
      name: 'Chopperia Informal',
      description: 'Regional',
      address: 'Guarapari',
      category: CityPoiCategory.restaurant,
      latitude: -20.6720163,
      longitude: -40.4975014,
    ),
    CityPoiDTO(
      id: 'poi-restaurant-churrascaria-carretao-gaucho',
      name: 'Churrascaria Carretão Gaucho',
      description: 'Churrasco',
      address: 'Rua José Capristano Nobre, Guarapari',
      category: CityPoiCategory.restaurant,
      latitude: -20.6529044,
      longitude: -40.4956337,
    ),
    CityPoiDTO(
      id: 'poi-restaurant-cia-comida',
      name: 'Cia & Comida',
      description: 'Regional',
      address: 'Guarapari',
      category: CityPoiCategory.restaurant,
      latitude: -20.6703032,
      longitude: -40.4984612,
    ),
    CityPoiDTO(
      id: 'poi-restaurant-cia-sabor',
      name: 'Cia & Sabor',
      description: 'Regional',
      address: 'Guarapari',
      category: CityPoiCategory.restaurant,
      latitude: -20.6697379,
      longitude: -40.49751,
    ),
    CityPoiDTO(
      id: 'poi-restaurant-cia-do-camarao',
      name: 'Cia do Camarão',
      description: 'Sabores locais e pratos da casa.',
      address: 'Avenida Maria de Lourdes Carvalho Dantas, Guarapari',
      category: CityPoiCategory.restaurant,
      latitude: -20.6516501,
      longitude: -40.4855483,
    ),
    CityPoiDTO(
      id: 'poi-restaurant-comida-e-cia',
      name: 'Comida e Cia',
      description: 'Sabores locais e pratos da casa.',
      address: 'Avenida José Alcântara Bourguingnon, Guarapari',
      category: CityPoiCategory.restaurant,
      latitude: -20.6527358,
      longitude: -40.4968734,
    ),
    CityPoiDTO(
      id: 'poi-restaurant-deck',
      name: 'Deck',
      description: 'Pizza, Burger',
      address: 'Guarapari',
      category: CityPoiCategory.restaurant,
      latitude: -20.6720688,
      longitude: -40.4976626,
    ),
    CityPoiDTO(
      id: 'poi-restaurant-delicias-de-bacalhao',
      name: 'Delicias de Bacalhao',
      description: 'Fish',
      address: 'Guarapari',
      category: CityPoiCategory.restaurant,
      latitude: -20.6710348,
      longitude: -40.4963034,
    ),
    CityPoiDTO(
      id: 'poi-restaurant-doce-prazer',
      name: 'Doce prazer',
      description: 'Sabores locais e pratos da casa.',
      address: 'Guarapari',
      category: CityPoiCategory.restaurant,
      latitude: -20.8112187,
      longitude: -40.6349303,
    ),
    CityPoiDTO(
      id: 'poi-restaurant-dona-cotinha-restaurante-e-pizzaria',
      name: 'Dona Cotinha - Restaurante e Pizzaria',
      description: 'Italian',
      address: 'Guarapari',
      category: CityPoiCategory.restaurant,
      latitude: -20.5810875,
      longitude: -40.5400293,
    ),
    CityPoiDTO(
      id: 'poi-restaurant-dona-cotinha-restaurante-e-pizzaria',
      name: 'Dona Cotinha - Restaurante e Pizzaria',
      description: 'Italian',
      address: 'Guarapari',
      category: CityPoiCategory.restaurant,
      latitude: -20.5811552,
      longitude: -40.5398914,
    ),
    CityPoiDTO(
      id: 'poi-restaurant-dona-orly',
      name: 'Dona Orly',
      description: 'Comida Caseira, Prato Feito, Marmitex, Self-Service',
      address: 'Rua Mariano A. Souza, Belo Horizonte, Guarapari',
      category: CityPoiCategory.restaurant,
      latitude: -20.736474,
      longitude: -40.5422454,
    ),
    CityPoiDTO(
      id: 'poi-restaurant-donatello-restaurante-e-pizzaria',
      name: 'Donatello Restaurante e Pizzaria',
      description: 'Pizza',
      address: 'Avenida Maria de Lourdes Carvalho Dantas',
      category: CityPoiCategory.restaurant,
      latitude: -20.6534829,
      longitude: -40.4894282,
    ),
    CityPoiDTO(
      id: 'poi-restaurant-emporio-bacutia-pizzaria-e-lanchonete',
      name: 'Empório Bacutia Pizzaria e Lanchonete',
      description: 'Sabores locais e pratos da casa.',
      address: 'Guarapari',
      category: CityPoiCategory.restaurant,
      latitude: -20.6524497,
      longitude: -40.4853176,
    ),
    CityPoiDTO(
      id: 'poi-restaurant-encontro-gourmet-padaria-e-restaurante',
      name: 'Encontro Gourmet Padaria e Restaurante',
      description: 'Sabores locais e pratos da casa.',
      address: 'Avenida Maria de Lourdes Carvalho Dantas',
      category: CityPoiCategory.restaurant,
      latitude: -20.6554035,
      longitude: -40.4924306,
    ),
    CityPoiDTO(
      id: 'poi-restaurant-espaco-sorriso',
      name: 'Espaço Sorriso',
      description: 'Sabores locais e pratos da casa.',
      address: 'Guarapari',
      category: CityPoiCategory.restaurant,
      latitude: -20.4860546,
      longitude: -40.439992,
    ),
    CityPoiDTO(
      id: 'poi-restaurant-farofa-carioca',
      name: 'Farofa Carioca',
      description: 'Sabores locais e pratos da casa.',
      address: 'Guarapari',
      category: CityPoiCategory.restaurant,
      latitude: -20.6565273,
      longitude: -40.4938703,
    ),
    CityPoiDTO(
      id: 'poi-restaurant-fillet-bar-e-restaurante',
      name: 'Fillet Bar e Restaurante',
      description: 'Sabores locais e pratos da casa.',
      address: 'Avenida Maria de Lourdes Carvalho Dantas',
      category: CityPoiCategory.restaurant,
      latitude: -20.6525317,
      longitude: -40.4867439,
    ),
    CityPoiDTO(
      id: 'poi-restaurant-frango-do-assis',
      name: 'Frango do Assis',
      description: 'Sabores locais e pratos da casa.',
      address: 'Guarapari',
      category: CityPoiCategory.restaurant,
      latitude: -20.6645255,
      longitude: -40.5040646,
    ),
    CityPoiDTO(
      id: 'poi-restaurant-free-dog-pizzaria-e-lanchonete',
      name: 'Free Dog Pizzaria e Lanchonete',
      description: 'Pizza, Sandwich',
      address: 'Avenida José Ferreira Ferro',
      category: CityPoiCategory.restaurant,
      latitude: -20.6562124,
      longitude: -40.4922658,
    ),
    CityPoiDTO(
      id: 'poi-restaurant-gostoso',
      name: 'Gostoso',
      description: 'Regional',
      address: 'Guarapari',
      category: CityPoiCategory.restaurant,
      latitude: -20.6731777,
      longitude: -40.4982096,
    ),
    CityPoiDTO(
      id: 'poi-restaurant-herois-burger',
      name: 'Heróis Burger',
      description: 'Burger',
      address: 'Guarapari',
      category: CityPoiCategory.restaurant,
      latitude: -20.6513284,
      longitude: -40.4792761,
    ),
    CityPoiDTO(
      id: 'poi-restaurant-hotel-coronado',
      name: 'Hotel Coronado',
      description: 'Sabores locais e pratos da casa.',
      address: 'Guarapari',
      category: CityPoiCategory.restaurant,
      latitude: -20.6738551,
      longitude: -40.4981284,
    ),
    CityPoiDTO(
      id: 'poi-restaurant-helio-restaurante-e-pizzaria',
      name: 'Hélio Restaurante e Pizzaria',
      description: 'Pizza',
      address: 'Rua Mônaco',
      category: CityPoiCategory.restaurant,
      latitude: -20.6512112,
      longitude: -40.4818123,
    ),
    CityPoiDTO(
      id: 'poi-restaurant-kebab-s',
      name: 'Kebab\'s',
      description: 'Pizza',
      address: 'Guarapari',
      category: CityPoiCategory.restaurant,
      latitude: -20.6605339,
      longitude: -40.4981243,
    ),
    CityPoiDTO(
      id: 'poi-restaurant-kibe-lanches',
      name: 'Kibe Lanches',
      description: 'Lebanese',
      address: 'Guarapari',
      category: CityPoiCategory.restaurant,
      latitude: -20.671917,
      longitude: -40.4979096,
    ),
    CityPoiDTO(
      id: 'poi-restaurant-lagoa-grande-restaurante',
      name: 'Lagoa Grande Restaurante',
      description: 'Sabores locais e pratos da casa.',
      address: 'Guarapari',
      category: CityPoiCategory.restaurant,
      latitude: -20.5036594,
      longitude: -40.3592779,
    ),
    CityPoiDTO(
      id: 'poi-restaurant-le-cave',
      name: 'Le Cave',
      description: 'Italian, Pizza',
      address: 'Guarapari',
      category: CityPoiCategory.restaurant,
      latitude: -20.6520423,
      longitude: -40.4859819,
    ),
    CityPoiDTO(
      id: 'poi-restaurant-lokal',
      name: 'Lokal',
      description: 'Sabores locais e pratos da casa.',
      address: 'Guarapari',
      category: CityPoiCategory.restaurant,
      latitude: -20.8349559,
      longitude: -40.6255289,
    ),
    CityPoiDTO(
      id: 'poi-lodging-bistro-pousada-orchidas',
      name: 'Bistro & Pousada Orchidas',
      description: 'Guest House',
      address: 'Guarapari',
      category: CityPoiCategory.lodging,
      latitude: -20.7398642,
      longitude: -40.5571611,
    ),
    CityPoiDTO(
      id: 'poi-lodging-biz-motel',
      name: 'Biz Motel',
      description: 'Motel',
      address: 'Guarapari',
      category: CityPoiCategory.lodging,
      latitude: -20.6260458,
      longitude: -40.4411686,
    ),
    CityPoiDTO(
      id: 'poi-lodging-bristol-residence-hotel',
      name: 'Bristol Residence Hotel',
      description: 'Hotel',
      address: 'Guarapari',
      category: CityPoiCategory.lodging,
      latitude: -20.6748329,
      longitude: -40.5005794,
    ),
    CityPoiDTO(
      id: 'poi-lodging-cantinho-de-curuca',
      name: 'Cantinho de Curuca',
      description: 'Hotel',
      address: 'Guarapari',
      category: CityPoiCategory.lodging,
      latitude: -20.7379051,
      longitude: -40.5386139,
    ),
    CityPoiDTO(
      id: 'poi-lodging-casa-de-penha',
      name: 'Casa de Penha',
      description: 'Guest House',
      address: 'Rua Las Vegas',
      category: CityPoiCategory.lodging,
      latitude: -20.6470874,
      longitude: -40.4835044,
    ),
    CityPoiDTO(
      id: 'poi-lodging-chacara-sabadini',
      name: 'Chácara Sabadini',
      description: 'Guest House',
      address: 'Rua Celso P Siqueira',
      category: CityPoiCategory.lodging,
      latitude: -20.571538,
      longitude: -40.494648,
    ),
    CityPoiDTO(
      id: 'poi-lodging-coral-de-ubu',
      name: 'Coral de Ubu',
      description: 'Hotel',
      address: 'Guarapari',
      category: CityPoiCategory.lodging,
      latitude: -20.8005378,
      longitude: -40.5945217,
    ),
    CityPoiDTO(
      id: 'poi-lodging-dinotel-guarapari',
      name: 'Dinotel Guarapari',
      description: 'Hotel',
      address: 'Avenida Davino Matos',
      category: CityPoiCategory.lodging,
      latitude: -20.6688965,
      longitude: -40.4985054,
    ),
    CityPoiDTO(
      id: 'poi-lodging-doce-vida-pousada',
      name: 'Doce Vida Pousada',
      description: 'Guest House',
      address: 'Guarapari',
      category: CityPoiCategory.lodging,
      latitude: -20.7322434,
      longitude: -40.5533152,
    ),
    CityPoiDTO(
      id: 'poi-lodging-flat-guarapari',
      name: 'Flat Guarapari',
      description: 'Guest House',
      address: 'Guarapari',
      category: CityPoiCategory.lodging,
      latitude: -20.6678265,
      longitude: -40.495547,
    ),
    CityPoiDTO(
      id: 'poi-lodging-fragata-hotel',
      name: 'Fragata Hotel',
      description: 'Hotel',
      address: 'Rua Brasília, Guarapari',
      category: CityPoiCategory.lodging,
      latitude: -20.6511746,
      longitude: -40.4744141,
    ),
    CityPoiDTO(
      id: 'poi-lodging-hospedaria-da-alice',
      name: 'Hospedaria da Alice',
      description: 'Hostel',
      address: 'Rua Mariano A. Souza, 217, Belo Horizonte, Guarapari',
      category: CityPoiCategory.lodging,
      latitude: -20.73677,
      longitude: -40.5427174,
    ),
    CityPoiDTO(
      id: 'poi-lodging-hotel-aquario',
      name: 'Hotel Aquario',
      description: 'Hotel',
      address: 'Rua Onze, Ubu, Anchieta',
      category: CityPoiCategory.lodging,
      latitude: -20.8008783,
      longitude: -40.590938,
    ),
    CityPoiDTO(
      id: 'poi-lodging-hotel-atlantico',
      name: 'Hotel Atlântico',
      description: 'Hotel',
      address: 'Guarapari',
      category: CityPoiCategory.lodging,
      latitude: -20.6709668,
      longitude: -40.4957347,
    ),
    CityPoiDTO(
      id: 'poi-lodging-hotel-bom-jesus',
      name: 'Hotel Bom Jesus',
      description: 'Hotel',
      address: 'Guarapari',
      category: CityPoiCategory.lodging,
      latitude: -20.6719604,
      longitude: -40.4988079,
    ),
    CityPoiDTO(
      id: 'poi-lodging-hotel-coronado',
      name: 'Hotel Coronado',
      description: 'Hotel',
      address: 'Guarapari',
      category: CityPoiCategory.lodging,
      latitude: -20.6738551,
      longitude: -40.4981284,
    ),
    CityPoiDTO(
      id: 'poi-lodging-hotel-fazenda-flamboyant',
      name: 'Hotel Fazenda Flamboyant',
      description: 'Hotel',
      address: 'Guarapari',
      category: CityPoiCategory.lodging,
      latitude: -20.5366647,
      longitude: -40.4529097,
    ),
    CityPoiDTO(
      id: 'poi-lodging-hotel-guarapousada',
      name: 'Hotel Guarapousada',
      description: 'Hotel',
      address: 'Avenida Antônio Guimarães, Itapebussu, Guarapari',
      category: CityPoiCategory.lodging,
      latitude: -20.6618889,
      longitude: -40.5032106,
    ),
    CityPoiDTO(
      id: 'poi-lodging-hotel-hotur-guarapari',
      name: 'Hotel Hotur Guarapari',
      description: 'Hotel',
      address: 'Guarapari',
      category: CityPoiCategory.lodging,
      latitude: -20.6754715,
      longitude: -40.5018665,
    ),
    CityPoiDTO(
      id: 'poi-lodging-hotel-meaipe',
      name: 'Hotel Meaipe',
      description: 'Hotel',
      address: 'Guarapari',
      category: CityPoiCategory.lodging,
      latitude: -20.7371443,
      longitude: -40.540325,
    ),
    CityPoiDTO(
      id: 'poi-attraction-amor-es',
      name: '#amor♥es',
      description: 'Ponto turístico imperdível em Guarapari.',
      address: 'Guarapari',
      category: CityPoiCategory.attraction,
      latitude: -20.658931,
      longitude: -40.4939774,
    ),
    CityPoiDTO(
      id: 'poi-attraction-casa-de-quarentena-dos-imigrantes',
      name: 'Casa de Quarentena dos Imigrantes',
      description: 'Ponto turístico imperdível em Guarapari.',
      address: 'Guarapari',
      category: CityPoiCategory.attraction,
      latitude: -20.8003493,
      longitude: -40.6481067,
    ),
    CityPoiDTO(
      id: 'poi-attraction-estatua-do-marlim-azul',
      name: 'Estátua do Marlim Azul',
      description: 'Patrimônio histórico que conta a história local.',
      address: 'Guarapari',
      category: CityPoiCategory.monument,
      latitude: -20.653017,
      longitude: -40.4786457,
    ),
    CityPoiDTO(
      id: 'poi-attraction-gruta-do-santana',
      name: 'Gruta do Santana',
      description: 'Patrimônio histórico que conta a história local.',
      address: 'Guarapari',
      category: CityPoiCategory.monument,
      latitude: -20.668388,
      longitude: -40.4959595,
    ),
    CityPoiDTO(
      id: 'poi-attraction-hotel-radium',
      name: 'Hotel Radium',
      description: 'Ponto turístico imperdível em Guarapari.',
      address: 'Guarapari',
      category: CityPoiCategory.attraction,
      latitude: -20.6741148,
      longitude: -40.4997484,
    ),
    CityPoiDTO(
      id: 'poi-attraction-igreja-jesuita',
      name: 'Igreja Jesuita',
      description: 'Patrimônio histórico que conta a história local.',
      address: 'Guarapari',
      category: CityPoiCategory.monument,
      latitude: -20.6695096,
      longitude: -40.4952393,
    ),
    CityPoiDTO(
      id: 'poi-attraction-mirante-da-lagoa',
      name: 'Mirante da Lagoa',
      description: 'Ponto turístico imperdível em Guarapari.',
      address: 'Guarapari',
      category: CityPoiCategory.attraction,
      latitude: -20.6147422,
      longitude: -40.4180343,
    ),
    CityPoiDTO(
      id: 'poi-attraction-mirante-de-buenos-aires',
      name: 'Mirante de Buenos Aires',
      description: 'Ponto turístico imperdível em Guarapari.',
      address: 'Guarapari',
      category: CityPoiCategory.attraction,
      latitude: -20.6027502,
      longitude: -40.5364213,
    ),
    CityPoiDTO(
      id: 'poi-attraction-mirante-do-brejo-herbaceo',
      name: 'Mirante do Brejo Herbáceo',
      description: 'Ponto turístico imperdível em Guarapari.',
      address: 'Guarapari',
      category: CityPoiCategory.attraction,
      latitude: -20.6036156,
      longitude: -40.4179413,
    ),
    CityPoiDTO(
      id: 'poi-attraction-pedreira',
      name: 'Pedreira',
      description: 'Ponto turístico imperdível em Guarapari.',
      address: 'Guarapari',
      category: CityPoiCategory.attraction,
      latitude: -20.6308125,
      longitude: -40.4761516,
    ),
    CityPoiDTO(
      id: 'poi-attraction-planet-sub',
      name: 'Planet Sub',
      description: 'Ponto turístico imperdível em Guarapari.',
      address: 'Guarapari',
      category: CityPoiCategory.attraction,
      latitude: -20.6752868,
      longitude: -40.4963639,
    ),
    CityPoiDTO(
      id: 'poi-attraction-poco-dos-jesuitas',
      name: 'Poço dos Jesuítas',
      description: 'Ponto turístico imperdível em Guarapari.',
      address: 'Guarapari',
      category: CityPoiCategory.attraction,
      latitude: -20.6665809,
      longitude: -40.4941538,
    ),
    CityPoiDTO(
      id: 'poi-attraction-praia-da-confissao',
      name: 'Praia da Confissão',
      description: 'Ponto turístico imperdível em Guarapari.',
      address: 'Guarapari',
      category: CityPoiCategory.attraction,
      latitude: -20.7397462,
      longitude: -40.5340225,
    ),
    CityPoiDTO(
      id: 'poi-attraction-praca-central-onaldo-nogueira-garcia',
      name: 'Praça Central Onaldo Nogueira Garcia',
      description: 'Parque urbano para aproveitar o dia ao ar livre.',
      address: 'Ubu, Anchieta',
      category: CityPoiCategory.culture,
      latitude: -20.8020323,
      longitude: -40.5942756,
    ),
    CityPoiDTO(
      id: 'poi-attraction-praca-ciriaco-ramalhete-de-oliveira',
      name: 'Praça Ciriaco Ramalhete de Oliveira',
      description: 'Parque urbano para aproveitar o dia ao ar livre.',
      address: 'Guarapari',
      category: CityPoiCategory.culture,
      latitude: -20.674627,
      longitude: -40.4999063,
    ),
    CityPoiDTO(
      id: 'poi-attraction-praca-ciriaco-ramalhete-de-oliveira',
      name: 'Praça Ciriaco Ramalhete de Oliveira',
      description: 'Parque urbano para aproveitar o dia ao ar livre.',
      address: 'Guarapari',
      category: CityPoiCategory.culture,
      latitude: -20.6743774,
      longitude: -40.5001453,
    ),
    CityPoiDTO(
      id: 'poi-attraction-praca-claudionor-coutinho',
      name: 'Praça Claudionor Coutinho',
      description: 'Parque urbano para aproveitar o dia ao ar livre.',
      address: 'Guarapari',
      category: CityPoiCategory.culture,
      latitude: -20.680694,
      longitude: -40.5059414,
    ),
    CityPoiDTO(
      id: 'poi-attraction-praca-claudio-rogerio-nunes-coutinho',
      name: 'Praça Cláudio Rogério Nunes Coutinho',
      description: 'Parque urbano para aproveitar o dia ao ar livre.',
      address: 'Guarapari',
      category: CityPoiCategory.culture,
      latitude: -20.4966362,
      longitude: -40.3558893,
    ),
    CityPoiDTO(
      id: 'poi-attraction-praca-dayse-rangel',
      name: 'Praça Dayse Rangel',
      description: 'Parque urbano para aproveitar o dia ao ar livre.',
      address: 'Guarapari',
      category: CityPoiCategory.culture,
      latitude: -20.6378411,
      longitude: -40.4827296,
    ),
    CityPoiDTO(
      id: 'poi-attraction-praca-elizete-elias-dias',
      name: 'Praça Elizete Elias Dias',
      description: 'Parque urbano para aproveitar o dia ao ar livre.',
      address: 'Guarapari',
      category: CityPoiCategory.culture,
      latitude: -20.6472529,
      longitude: -40.4994877,
    ),
    CityPoiDTO(
      id: 'poi-nature-pedra-do-elefante',
      name: 'Pedra do Elefante',
      description:
          'Formação rochosa símbolo de Buenos Aires, com trilha e vista panorâmica.',
      address: 'Buenos Aires, Guarapari',
      category: CityPoiCategory.nature,
      latitude: -20.6054019,
      longitude: -40.5330378,
      tags: ['trilha', 'mirante'],
    ),
    CityPoiDTO(
      id: 'poi-nature-pedra-do-cruzeiro',
      name: 'Pedra do Cruzeiro',
      description:
          'Mirante natural em Buenos Aires com vista para o litoral de Guarapari.',
      address: 'Buenos Aires, Guarapari',
      category: CityPoiCategory.nature,
      latitude: -20.5927876,
      longitude: -40.5298941,
      tags: ['mirante'],
    ),
    CityPoiDTO(
      id: 'poi-nature-morro-da-serra-grande',
      name: 'Morro da Serra Grande',
      description:
          'Ponto alto de mata atlântica ideal para caminhadas em Buenos Aires.',
      address: 'Buenos Aires, Guarapari',
      category: CityPoiCategory.nature,
      latitude: -20.60157,
      longitude: -40.5277992,
      tags: ['trilha', 'mirante'],
    ),
    CityPoiDTO(
      id: 'poi-beach-praia-boca-da-baleia',
      name: 'Praia Boca da Baleia',
      description:
          'Praia icônica de Guarapari, excelente para aproveitar o litoral.',
      address: 'Guarapari',
      category: CityPoiCategory.beach,
      latitude: -20.8368984,
      longitude: -40.6315994,
    ),
    CityPoiDTO(
      id: 'poi-beach-praia-boiao',
      name: 'Praia Boião',
      description:
          'Praia icônica de Guarapari, excelente para aproveitar o litoral.',
      address: 'Guarapari',
      category: CityPoiCategory.beach,
      latitude: -20.6279628,
      longitude: -40.4663096,
    ),
    CityPoiDTO(
      id: 'poi-beach-praia-guaibura',
      name: 'Praia Guaibura',
      description:
          'Praia icônica de Guarapari, excelente para aproveitar o litoral.',
      address: 'Guarapari',
      category: CityPoiCategory.beach,
      latitude: -20.725186,
      longitude: -40.5234631,
    ),
    CityPoiDTO(
      id: 'poi-beach-praia-maimba',
      name: 'Praia Maimbá',
      description:
          'Praia icônica de Guarapari, excelente para aproveitar o litoral.',
      address: 'Guarapari',
      category: CityPoiCategory.beach,
      latitude: -20.7713725,
      longitude: -40.5739648,
    ),
    CityPoiDTO(
      id: 'poi-beach-praia-maimba',
      name: 'Praia Maimbá',
      description:
          'Praia icônica de Guarapari, excelente para aproveitar o litoral.',
      address: 'Guarapari',
      category: CityPoiCategory.beach,
      latitude: -20.7592731,
      longitude: -40.5662332,
    ),
    CityPoiDTO(
      id: 'poi-beach-praia-maimba',
      name: 'Praia Maimbá',
      description:
          'Praia icônica de Guarapari, excelente para aproveitar o litoral.',
      address: 'Guarapari',
      category: CityPoiCategory.beach,
      latitude: -20.7458701,
      longitude: -40.5548879,
    ),
    CityPoiDTO(
      id: 'poi-beach-praia-peracanga',
      name: 'Praia Peracanga',
      description:
          'Praia icônica de Guarapari, excelente para aproveitar o litoral.',
      address: 'Guarapari',
      category: CityPoiCategory.beach,
      latitude: -20.7307859,
      longitude: -40.5261056,
    ),
    CityPoiDTO(
      id: 'poi-beach-praia-recanto-dos-amores',
      name: 'Praia Recanto dos Amores',
      description:
          'Praia icônica de Guarapari, excelente para aproveitar o litoral.',
      address: 'Guarapari',
      category: CityPoiCategory.beach,
      latitude: -20.6292695,
      longitude: -40.4653139,
    ),
    CityPoiDTO(
      id: 'poi-beach-praia-santa-monica',
      name: 'Praia Santa Mônica',
      description:
          'Praia icônica de Guarapari, excelente para aproveitar o litoral.',
      address: 'Guarapari',
      category: CityPoiCategory.beach,
      latitude: -20.6270159,
      longitude: -40.4548392,
    ),
    CityPoiDTO(
      id: 'poi-beach-praia-setibao',
      name: 'Praia Setibão',
      description:
          'Praia icônica de Guarapari, excelente para aproveitar o litoral.',
      address: 'Guarapari',
      category: CityPoiCategory.beach,
      latitude: -20.6260635,
      longitude: -40.422129,
    ),
    CityPoiDTO(
      id: 'poi-beach-praia-d-ule',
      name: 'Praia d\'Ulé',
      description:
          'Praia icônica de Guarapari, excelente para aproveitar o litoral.',
      address: 'Guarapari',
      category: CityPoiCategory.beach,
      latitude: -20.5627267,
      longitude: -40.3916295,
    ),
    CityPoiDTO(
      id: 'poi-beach-praia-da-aldeia',
      name: 'Praia da Aldeia',
      description:
          'Praia icônica de Guarapari, excelente para aproveitar o litoral.',
      address: 'Guarapari',
      category: CityPoiCategory.beach,
      latitude: -20.6435273,
      longitude: -40.4681014,
    ),
    CityPoiDTO(
      id: 'poi-beach-praia-da-aldeia',
      name: 'Praia da Aldeia',
      description:
          'Praia icônica de Guarapari, excelente para aproveitar o litoral.',
      address: 'Guarapari',
      category: CityPoiCategory.beach,
      latitude: -20.6444265,
      longitude: -40.4665926,
    ),
    CityPoiDTO(
      id: 'poi-beach-praia-da-areia-preta',
      name: 'Praia da Areia Preta',
      description:
          'Praia icônica de Guarapari, excelente para aproveitar o litoral.',
      address: 'Guarapari',
      category: CityPoiCategory.beach,
      latitude: -20.6755923,
      longitude: -40.4995644,
    ),
    CityPoiDTO(
      id: 'poi-beach-praia-da-baleia',
      name: 'Praia da Baleia',
      description:
          'Praia icônica de Guarapari, excelente para aproveitar o litoral.',
      address: 'Guarapari',
      category: CityPoiCategory.beach,
      latitude: -20.5063024,
      longitude: -40.3560889,
    ),
    CityPoiDTO(
      id: 'poi-beach-praia-da-cerca',
      name: 'Praia da Cerca',
      description:
          'Praia icônica de Guarapari, excelente para aproveitar o litoral.',
      address: 'Guarapari',
      category: CityPoiCategory.beach,
      latitude: -20.652956,
      longitude: -40.4724894,
    ),
    CityPoiDTO(
      id: 'poi-beach-praia-da-confissao',
      name: 'Praia da Confissão',
      description:
          'Praia icônica de Guarapari, excelente para aproveitar o litoral.',
      address: 'Guarapari',
      category: CityPoiCategory.beach,
      latitude: -20.7397263,
      longitude: -40.5342164,
    ),
    CityPoiDTO(
      id: 'poi-beach-praia-da-fonte',
      name: 'Praia da Fonte',
      description:
          'Praia icônica de Guarapari, excelente para aproveitar o litoral.',
      address: 'Rua Vereador Ozias Santana, Guarapari',
      category: CityPoiCategory.beach,
      latitude: -20.6672423,
      longitude: -40.4939688,
    ),
    CityPoiDTO(
      id: 'poi-beach-praia-da-fonte',
      name: 'Praia da Fonte',
      description:
          'Praia icônica de Guarapari, excelente para aproveitar o litoral.',
      address: 'Guarapari',
      category: CityPoiCategory.beach,
      latitude: -20.6676746,
      longitude: -40.4931118,
    ),
    CityPoiDTO(
      id: 'poi-beach-praia-das-castanheiras',
      name: 'Praia das Castanheiras',
      description:
          'Praia icônica de Guarapari, excelente para aproveitar o litoral.',
      address: 'Guarapari',
      category: CityPoiCategory.beach,
      latitude: -20.6723398,
      longitude: -40.496764,
    ),
    CityPoiDTO(
      id: 'poi-beach-praia-das-castanheiras',
      name: 'Praia das Castanheiras',
      description:
          'Praia icônica de Guarapari, excelente para aproveitar o litoral.',
      address: 'Guarapari',
      category: CityPoiCategory.beach,
      latitude: -20.8128193,
      longitude: -40.6417888,
    ),
    CityPoiDTO(
      id: 'poi-beach-praia-das-conchas',
      name: 'Praia das Conchas',
      description:
          'Praia icônica de Guarapari, excelente para aproveitar o litoral.',
      address: 'Guarapari',
      category: CityPoiCategory.beach,
      latitude: -20.6457766,
      longitude: -40.4675213,
    ),
    CityPoiDTO(
      id: 'poi-beach-praia-das-falesias',
      name: 'Praia das Falésias',
      description:
          'Praia icônica de Guarapari, excelente para aproveitar o litoral.',
      address: 'Guarapari',
      category: CityPoiCategory.beach,
      latitude: -20.7822977,
      longitude: -40.5759631,
    ),
    CityPoiDTO(
      id: 'poi-beach-praia-das-virtudes',
      name: 'Praia das Virtudes',
      description:
          'Praia icônica de Guarapari, excelente para aproveitar o litoral.',
      address: 'Guarapari',
      category: CityPoiCategory.beach,
      latitude: -20.6694104,
      longitude: -40.4934455,
    ),
    CityPoiDTO(
      id: 'poi-beach-praia-de-guanabara',
      name: 'Praia de Guanabara',
      description:
          'Praia icônica de Guarapari, excelente para aproveitar o litoral.',
      address: 'Guarapari',
      category: CityPoiCategory.beach,
      latitude: -20.824771,
      longitude: -40.6169132,
    ),
    CityPoiDTO(
      id: 'poi-beach-praia-de-interlagos',
      name: 'Praia de Interlagos',
      description:
          'Praia icônica de Guarapari, excelente para aproveitar o litoral.',
      address: 'Guarapari',
      category: CityPoiCategory.beach,
      latitude: -20.48345,
      longitude: -40.3481343,
    ),
    CityPoiDTO(
      id: 'poi-beach-praia-de-mateus-lopes',
      name: 'Praia de Mateus Lopes',
      description:
          'Praia icônica de Guarapari, excelente para aproveitar o litoral.',
      address: 'Guarapari',
      category: CityPoiCategory.beach,
      latitude: -20.6375417,
      longitude: -40.4688808,
    ),
    CityPoiDTO(
      id: 'poi-beach-praia-de-meaipe',
      name: 'Praia de Meaípe',
      description:
          'Praia icônica de Guarapari, excelente para aproveitar o litoral.',
      address: 'Guarapari',
      category: CityPoiCategory.beach,
      latitude: -20.7396332,
      longitude: -40.5431219,
    ),
    CityPoiDTO(
      id: 'poi-beach-praia-de-parati',
      name: 'Praia de Parati',
      description:
          'Praia icônica de Guarapari, excelente para aproveitar o litoral.',
      address: 'Guarapari',
      category: CityPoiCategory.beach,
      latitude: -20.8115155,
      longitude: -40.6092972,
    ),
    CityPoiDTO(
      id: 'poi-beach-praia-de-parati',
      name: 'Praia de Parati',
      description:
          'Praia icônica de Guarapari, excelente para aproveitar o litoral.',
      address: 'Guarapari',
      category: CityPoiCategory.beach,
      latitude: -20.8053154,
      longitude: -40.6019781,
    ),
    CityPoiDTO(
      id: 'poi-beach-praia-de-ponta-da-fruta',
      name: 'Praia de Ponta da Fruta',
      description:
          'Praia icônica de Guarapari, excelente para aproveitar o litoral.',
      address: 'Guarapari',
      category: CityPoiCategory.beach,
      latitude: -20.5287135,
      longitude: -40.3704889,
    ),
    CityPoiDTO(
      id: 'poi-beach-praia-de-setiba',
      name: 'Praia de Setiba',
      description:
          'Praia icônica de Guarapari, excelente para aproveitar o litoral.',
      address: 'Guarapari',
      category: CityPoiCategory.beach,
      latitude: -20.6352787,
      longitude: -40.4375718,
    ),
    CityPoiDTO(
      id: 'poi-beach-praia-de-setiba-grande',
      name: 'Praia de Setiba Grande',
      description:
          'Praia icônica de Guarapari, excelente para aproveitar o litoral.',
      address: 'Guarapari',
      category: CityPoiCategory.beach,
      latitude: -20.6362976,
      longitude: -40.4284362,
    ),
    CityPoiDTO(
      id: 'poi-beach-praia-de-ubu',
      name: 'Praia de Ubu',
      description:
          'Praia icônica de Guarapari, excelente para aproveitar o litoral.',
      address: 'Guarapari',
      category: CityPoiCategory.beach,
      latitude: -20.8028802,
      longitude: -40.5913505,
    ),
    CityPoiDTO(
      id: 'poi-beach-praia-do-alem',
      name: 'Praia do Além',
      description:
          'Praia icônica de Guarapari, excelente para aproveitar o litoral.',
      address: 'Guarapari',
      category: CityPoiCategory.beach,
      latitude: -20.7956742,
      longitude: -40.5804239,
    ),
    CityPoiDTO(
      id: 'poi-beach-praia-do-bacutia',
      name: 'Praia do Bacutia',
      description:
          'Praia icônica de Guarapari, excelente para aproveitar o litoral.',
      address: 'Guarapari',
      category: CityPoiCategory.beach,
      latitude: -20.7336058,
      longitude: -40.530129,
    ),
    CityPoiDTO(
      id: 'poi-beach-praia-do-camping',
      name: 'Praia do Camping',
      description:
          'Praia icônica de Guarapari, excelente para aproveitar o litoral.',
      address: 'Guarapari',
      category: CityPoiCategory.beach,
      latitude: -20.6334672,
      longitude: -40.4415478,
    ),
    CityPoiDTO(
      id: 'poi-beach-praia-do-ermitao',
      name: 'Praia do Ermitão',
      description:
          'Praia icônica de Guarapari, excelente para aproveitar o litoral.',
      address: 'Guarapari',
      category: CityPoiCategory.beach,
      latitude: -20.6571458,
      longitude: -40.4689057,
    ),
    CityPoiDTO(
      id: 'poi-beach-praia-do-meio',
      name: 'Praia do Meio',
      description:
          'Praia icônica de Guarapari, excelente para aproveitar o litoral.',
      address: 'Guarapari',
      category: CityPoiCategory.beach,
      latitude: -20.6741047,
      longitude: -40.4972832,
    ),
    CityPoiDTO(
      id: 'poi-beach-praia-do-meio',
      name: 'Praia do Meio',
      description:
          'Praia icônica de Guarapari, excelente para aproveitar o litoral.',
      address: 'Guarapari',
      category: CityPoiCategory.beach,
      latitude: -20.6363778,
      longitude: -40.4686194,
    ),
    CityPoiDTO(
      id: 'poi-beach-praia-do-morro',
      name: 'Praia do Morro',
      description:
          'Praia icônica de Guarapari, excelente para aproveitar o litoral.',
      address: 'Avenida Beira Mar, Guarapari',
      category: CityPoiCategory.beach,
      latitude: -20.6573121,
      longitude: -40.4844174,
    ),
    CityPoiDTO(
      id: 'poi-beach-praia-do-netuno',
      name: 'Praia do Netuno',
      description:
          'Praia icônica de Guarapari, excelente para aproveitar o litoral.',
      address: 'Guarapari',
      category: CityPoiCategory.beach,
      latitude: -20.6470577,
      longitude: -40.4695726,
    ),
    CityPoiDTO(
      id: 'poi-beach-praia-do-porto-velho',
      name: 'Praia do Porto Velho',
      description:
          'Praia icônica de Guarapari, excelente para aproveitar o litoral.',
      address: 'Guarapari',
      category: CityPoiCategory.beach,
      latitude: -20.8288579,
      longitude: -40.6318768,
    ),
    CityPoiDTO(
      id: 'poi-beach-praia-do-riacho',
      name: 'Praia do Riacho',
      description:
          'Praia icônica de Guarapari, excelente para aproveitar o litoral.',
      address: 'Guarapari',
      category: CityPoiCategory.beach,
      latitude: -20.7007333,
      longitude: -40.513109,
    ),
    CityPoiDTO(
      id: 'poi-beach-praia-do-saco',
      name: 'Praia do Saco',
      description:
          'Praia icônica de Guarapari, excelente para aproveitar o litoral.',
      address: 'Guarapari',
      category: CityPoiCategory.beach,
      latitude: -20.6348388,
      longitude: -40.469921,
    ),
    CityPoiDTO(
      id: 'poi-beach-praia-do-sul',
      name: 'Praia do Sul',
      description:
          'Praia icônica de Guarapari, excelente para aproveitar o litoral.',
      address: 'Guarapari',
      category: CityPoiCategory.beach,
      latitude: -20.6601772,
      longitude: -40.4751371,
    ),
    CityPoiDTO(
      id: 'poi-beach-praia-do-urubu',
      name: 'Praia do Urubu',
      description:
          'Praia icônica de Guarapari, excelente para aproveitar o litoral.',
      address: 'Guarapari',
      category: CityPoiCategory.beach,
      latitude: -20.7417778,
      longitude: -40.5365646,
    ),
    CityPoiDTO(
      id: 'poi-beach-praia-dos-adventistas',
      name: 'Praia dos Adventistas',
      description:
          'Praia icônica de Guarapari, excelente para aproveitar o litoral.',
      address: 'Guarapari',
      category: CityPoiCategory.beach,
      latitude: -20.6403202,
      longitude: -40.4699792,
    ),
    CityPoiDTO(
      id: 'poi-beach-praia-dos-carais',
      name: 'Praia dos Caraís',
      description:
          'Praia icônica de Guarapari, excelente para aproveitar o litoral.',
      address: 'Guarapari',
      category: CityPoiCategory.beach,
      latitude: -20.600955,
      longitude: -40.4100228,
    ),
    CityPoiDTO(
      id: 'poi-beach-praia-dos-castelhanos',
      name: 'Praia dos Castelhanos',
      description:
          'Praia icônica de Guarapari, excelente para aproveitar o litoral.',
      address: 'Guarapari',
      category: CityPoiCategory.beach,
      latitude: -20.8361648,
      longitude: -40.6253155,
    ),
    CityPoiDTO(
      id: 'poi-beach-praia-dos-namorados',
      name: 'Praia dos Namorados',
      description:
          'Praia icônica de Guarapari, excelente para aproveitar o litoral.',
      address: 'Rua Edisio Cirne, Guarapari',
      category: CityPoiCategory.beach,
      latitude: -20.671406,
      longitude: -40.4952237,
    ),
    CityPoiDTO(
      id: 'poi-beach-praia-dos-padres',
      name: 'Praia dos Padres',
      description:
          'Praia icônica de Guarapari, excelente para aproveitar o litoral.',
      address: 'Guarapari',
      category: CityPoiCategory.beach,
      latitude: -20.7359485,
      longitude: -40.5335504,
    ),
    CityPoiDTO(
      id: 'poi-health-caps',
      name: 'CAPS',
      description: 'Referência em atendimento em Guarapari.',
      address: 'Guarapari',
      category: CityPoiCategory.health,
      latitude: -20.8099687,
      longitude: -40.635498,
    ),
    CityPoiDTO(
      id: 'poi-health-centro-de-especialidades-unificado-ceu',
      name: 'Centro de Especialidades Unificado - Ceu',
      description: 'Referência em atendimento em Guarapari.',
      address: 'Rodovia Edival José Petri, Vila Residêncial Samarco, Anchieta',
      category: CityPoiCategory.health,
      latitude: -20.8126289,
      longitude: -40.6336496,
    ),
    CityPoiDTO(
      id: 'poi-health-hospital-geral-dr-luiz-buaiz',
      name: 'Hospital Geral Dr. Luiz Buaiz',
      description: 'Referência em atendimento em Guarapari.',
      address: 'R. Pastor Simão Pedro Manske, Village da Praia, Guarapari',
      category: CityPoiCategory.health,
      latitude: -20.6448967,
      longitude: -40.4764769,
    ),
    CityPoiDTO(
      id: 'poi-health-hospital-nossa-senhora-da-conceicao',
      name: 'Hospital Nossa Senhora da Conceição',
      description: 'Referência em atendimento em Guarapari.',
      address: 'Rua Doutor Gerson da Silva Freire, 91, Guarapari',
      category: CityPoiCategory.health,
      latitude: -20.677704,
      longitude: -40.5056966,
    ),
    CityPoiDTO(
      id: 'poi-health-hospital-sao-judas-tadeu',
      name: 'Hospital São Judas Tadeu',
      description: 'Referência em atendimento em Guarapari.',
      address: 'Rua Santana do Iapo, 54, Guarapari',
      category: CityPoiCategory.health,
      latitude: -20.6634695,
      longitude: -40.500169,
    ),
    CityPoiDTO(
      id: 'poi-nature-cachoeira-engenheiro-reeve',
      name: 'Cachoeira Engenheiro Reeve (Matilde)',
      description:
          'Cachoeira citada como a mais famosa do município, no distrito de Matilde.',
      address: 'Distrito de Matilde, Alfredo Chaves - ES',
      category: CityPoiCategory.nature,
      latitude: -20.5588949,
      longitude: -40.8166845,
      priority: 5,
      tags: ['cachoeira', 'matilde', 'natureza'],
    ),
    CityPoiDTO(
      id: 'poi-attraction-tunel-de-matilde',
      name: 'Túnel de Matilde',
      description: 'Atrativo turístico em Matilde.',
      address: 'Distrito de Matilde, Alfredo Chaves - ES',
      category: CityPoiCategory.attraction,
      latitude: -20.557,
      longitude: -40.805,
      priority: 6,
      tags: ['matilde', 'turismo', 'história'],
    ),
    CityPoiDTO(
      id: 'poi-culture-estacao-ferroviaria-matilde',
      name: 'Estação Ferroviária de Matilde',
      description:
          'Antiga estação ferroviária (OSM: "Mathilde"), hoje ponto de visitação em Matilde.',
      address: 'Matilde, Alfredo Chaves - ES',
      category: CityPoiCategory.culture,
      latitude: -20.5575140,
      longitude: -40.8133481,
      priority: 7,
      tags: ['matilde', 'estação', 'história'],
    ),
    CityPoiDTO(
      id: 'poi-attraction-rampa-voo-livre-cachoeira-alta',
      name: 'Rampa de Voo Livre de Cachoeira Alta',
      description: 'Ponto de voo livre e turismo de aventura.',
      address: 'Cachoeira Alta, Alfredo Chaves - ES',
      category: CityPoiCategory.attraction,
      latitude: -20.668,
      longitude: -40.785,
      priority: 6,
      tags: ['voo livre', 'aventura', 'cachoeira alta'],
    ),
    CityPoiDTO(
      id: 'poi-culture-estacao-ferroviaria-ibitirui',
      name: 'Estação Ferroviária de Ibitiruí',
      description: 'Parada de trem (OSM: estação "Ibitiruí").',
      address: 'Ibitiruí, Alfredo Chaves - ES',
      category: CityPoiCategory.culture,
      latitude: -20.6002700,
      longitude: -40.8588742,
      priority: 7,
      tags: ['ibitiruí', 'estação', 'história'],
    ),
    CityPoiDTO(
      id: 'poi-church-igreja-nossa-senhora-da-conceicao',
      name: 'Igreja Nossa Senhora da Conceição',
      description: 'Igreja citada como atrativo turístico em Alfredo Chaves.',
      address: 'Centro, Alfredo Chaves - ES',
      category: CityPoiCategory.church,
      latitude: -20.6353808,
      longitude: -40.7497368,
      priority: 7,
      tags: ['igreja', 'centro'],
    ),
    const CityPoiDTO(
      id: 'poi-nature-cachoeira-piripitinga',
      name: 'Cachoeira de Piripitinga',
      description: 'Cachoeira citada pela Prefeitura de Alfredo Chaves.',
      address: 'Batatal, Alfredo Chaves - ES',
      category: CityPoiCategory.nature,
      latitude: -20.594081,
      longitude: -40.7596686,
      priority: 5,
      tags: ['cachoeira', 'natureza'],
    ),
    const CityPoiDTO(
      id: 'poi-nature-cachoeira-pinon',
      name: 'Cachoeira do Pinon',
      description: 'Cachoeira citada pela Prefeitura de Alfredo Chaves.',
      address: 'Carolina, Alfredo Chaves - ES',
      category: CityPoiCategory.nature,
      latitude: -20.5492676,
      longitude: -40.8550816,
      priority: 5,
      tags: ['cachoeira', 'natureza'],
    ),
    CityPoiDTO(
      id: 'poi-nature-cachoeira-maravilha',
      name: 'Cachoeira de Maravilha',
      description: 'Cachoeira na região de Maravilha (São Roque de Maravilha).',
      address: 'Maravilha, Alfredo Chaves - ES',
      category: CityPoiCategory.nature,
      latitude: -20.5528697,
      longitude: -40.8721556,
      priority: 5,
      tags: ['cachoeira', 'natureza', 'maravilha'],
    ),
    const CityPoiDTO(
      id: 'poi-nature-cachoeira-vovo-lucia',
      name: 'Cachoeira da Vovó Lúcia (Ibitiruí)',
      description: 'Cachoeira em Ibitiruí, Alfredo Chaves.',
      address: 'Ibitiruí, Alfredo Chaves - ES',
      category: CityPoiCategory.nature,
      latitude: -20.5997164,
      longitude: -40.8491966,
      priority: 5,
      tags: ['cachoeira', 'ibitiruí', 'natureza'],
    ),
    const CityPoiDTO(
      id: 'poi-nature-cachoeira-quintino',
      name: 'Cachoeira do Quintino',
      description: 'Cachoeira citada pela Prefeitura de Alfredo Chaves.',
      address: 'Crubixá, Alfredo Chaves - ES',
      category: CityPoiCategory.nature,
      latitude: -20.6644246,
      longitude: -40.9015559,
      priority: 5,
      tags: ['cachoeira', 'natureza'],
    ),
    const CityPoiDTO(
      id: 'poi-nature-cachoeira-daros',
      name: 'Cachoeira do Darós',
      description: 'Cachoeira em Alfredo Chaves (OSM: Cachoeira do Darós).',
      address: 'Alfredo Chaves - ES',
      category: CityPoiCategory.nature,
      latitude: -20.5485179,
      longitude: -40.8537904,
      priority: 5,
      tags: ['cachoeira', 'natureza'],
    ),
    const CityPoiDTO(
      id: 'poi-nature-cachoeira-iracema',
      name: 'Cachoeira de Iracema',
      description: 'Cachoeira em Alfredo Chaves (OSM: Cachoeira de Iracema).',
      address: 'Alfredo Chaves - ES',
      category: CityPoiCategory.nature,
      latitude: -20.5027167,
      longitude: -40.8694927,
      priority: 5,
      tags: ['cachoeira', 'natureza'],
    ),
    const CityPoiDTO(
      id: 'poi-nature-cachoeira-iraceminha',
      name: 'Cachoeira de Iraceminha',
      description:
          'Cachoeira em Alfredo Chaves (OSM: Cachoeira de Iraceminha).',
      address: 'Alfredo Chaves - ES',
      category: CityPoiCategory.nature,
      latitude: -20.5055490,
      longitude: -40.8702554,
      priority: 5,
      tags: ['cachoeira', 'natureza'],
    ),
    const CityPoiDTO(
      id: 'poi-nature-cachoeira-paganini',
      name: 'Cachoeira do Paganini',
      description: 'Cachoeira em Alfredo Chaves (OSM: Cachoeira do Paganini).',
      address: 'Alfredo Chaves - ES',
      category: CityPoiCategory.nature,
      latitude: -20.6485680,
      longitude: -40.8694645,
      priority: 5,
      tags: ['cachoeira', 'natureza'],
    ),
    const CityPoiDTO(
      id: 'poi-nature-cachoeira-alta',
      name: 'Cachoeira Alta',
      description: 'Cachoeira em Alfredo Chaves (OSM: Cachoeira Alta).',
      address: 'Cachoeira Alta, Alfredo Chaves - ES',
      category: CityPoiCategory.nature,
      latitude: -20.6784737,
      longitude: -40.7806290,
      priority: 5,
      tags: ['cachoeira', 'natureza', 'cachoeira alta'],
    ),
    const CityPoiDTO(
      id: 'poi-nature-cachoeira-da-luz',
      name: 'Cachoeira da Luz',
      description: 'Cachoeira em Alfredo Chaves (OSM: Cachoeira da Luz).',
      address: 'Alfredo Chaves - ES',
      category: CityPoiCategory.nature,
      latitude: -20.7022317,
      longitude: -40.7811841,
      priority: 5,
      tags: ['cachoeira', 'natureza'],
    ),
    const CityPoiDTO(
      id: 'poi-nature-cachoeira-do-cafundo',
      name: 'Cachoeira do Cafundó',
      description: 'Cachoeira em Alfredo Chaves (OSM: Cachoeira do Cafundó).',
      address: 'Alfredo Chaves - ES',
      category: CityPoiCategory.nature,
      latitude: -20.7037861,
      longitude: -40.7777183,
      priority: 5,
      tags: ['cachoeira', 'natureza'],
    ),
    const CityPoiDTO(
      id: 'poi-nature-cachoeira-do-pasto',
      name: 'Cachoeira do Pasto',
      description: 'Cachoeira em Alfredo Chaves (OSM: Cachoeira do Pasto).',
      address: 'Alfredo Chaves - ES',
      category: CityPoiCategory.nature,
      latitude: -20.5562983,
      longitude: -40.8653546,
      priority: 5,
      tags: ['cachoeira', 'natureza'],
    ),
    const CityPoiDTO(
      id: 'poi-nature-pedra-do-gururu',
      name: 'Pedra do Gururu',
      description: 'Pico/elevação em Alfredo Chaves (OSM: Pedra do Gururu).',
      address: 'Alfredo Chaves - ES',
      category: CityPoiCategory.nature,
      latitude: -20.6196656,
      longitude: -40.7527691,
      priority: 6,
      tags: ['natureza', 'trilha', 'mirante'],
    ),
    const CityPoiDTO(
      id: 'poi-nature-rppn-alto-gururu',
      name: 'RPPN Alto Gururu',
      description:
          'Reserva Particular do Patrimônio Natural (OSM: Alto Gururu).',
      address: 'Alfredo Chaves - ES',
      category: CityPoiCategory.nature,
      latitude: -20.6189971,
      longitude: -40.7565558,
      priority: 6,
      tags: ['natureza', 'reserva', 'gururu'],
    ),
    const CityPoiDTO(
      id: 'poi-nature-pedra-de-santo-antonio',
      name: 'Pedra de Santo Antônio',
      description:
          'Pico/elevação em Alfredo Chaves (OSM: Pedra de Santo Antônio).',
      address: 'Alfredo Chaves - ES',
      category: CityPoiCategory.nature,
      latitude: -20.4423297,
      longitude: -40.9917037,
      priority: 6,
      tags: ['natureza', 'trilha'],
    ),
    const CityPoiDTO(
      id: 'poi-church-capela-sao-benedito',
      name: 'Capela de São Benedito',
      description: 'Capela citada como atrativo turístico em Alfredo Chaves.',
      address: 'Alfredo Chaves - ES',
      category: CityPoiCategory.church,
      latitude: -20.6363388,
      longitude: -40.7505049,
      priority: 8,
      tags: ['igreja', 'capela', 'centro'],
    ),
    const CityPoiDTO(
      id: 'poi-church-capela-sao-roque',
      name: 'Capela de São Roque',
      description: 'Capela em Alfredo Chaves (OSM: Capela de São Roque).',
      address: 'Alfredo Chaves - ES',
      category: CityPoiCategory.church,
      latitude: -20.5631839,
      longitude: -40.8485983,
      priority: 8,
      tags: ['igreja', 'capela'],
    ),
    const CityPoiDTO(
      id: 'poi-church-igreja-sao-roque',
      name: 'Igreja de São Roque',
      description: 'Igreja em Alfredo Chaves (OSM: Igreja de São Roque).',
      address: 'São Roque de Maravilha, Alfredo Chaves - ES',
      category: CityPoiCategory.church,
      latitude: -20.5537846,
      longitude: -40.8792044,
      priority: 8,
      tags: ['igreja', 'são roque', 'maravilha'],
    ),
    const CityPoiDTO(
      id: 'poi-church-igreja-sagrada-familia-sagrada-familia',
      name: 'Igreja da Sagrada Família',
      description: 'Igreja em Alfredo Chaves (Sagrada Família).',
      address: 'Sagrada Família, Alfredo Chaves - ES',
      category: CityPoiCategory.church,
      latitude: -20.5797719,
      longitude: -40.6977541,
      priority: 8,
      tags: ['igreja', 'sagrada família'],
    ),
    const CityPoiDTO(
      id: 'poi-church-igreja-sagrada-familia-vila-nova-maravilha',
      name: 'Igreja da Sagrada Família (Vila Nova de Maravilha)',
      description: 'Igreja em Alfredo Chaves (Vila Nova de Maravilha).',
      address: 'Vila Nova de Maravilha, Alfredo Chaves - ES',
      category: CityPoiCategory.church,
      latitude: -20.5866330,
      longitude: -40.9494174,
      priority: 8,
      tags: ['igreja', 'sagrada família', 'maravilha'],
    ),
    CityPoiDTO(
      id: 'poi-attraction-parque-exposicoes-reginaldo-roque-giori',
      name: 'Parque de Exposições Reginaldo Roque Giori',
      description: 'Parque de exposições citado em publicações institucionais.',
      address: 'Alfredo Chaves - ES',
      category: CityPoiCategory.attraction,
      latitude: -20.6379071,
      longitude: -40.7427644,
      priority: 8,
      tags: ['eventos', 'exposicao', 'agro'],
    ),
    CityPoiDTO(
      id: 'poi-culture-casa-do-artesao',
      name: 'Casa do Artesão',
      description: 'Espaço de valorização da cultura local e economia criativa.',
      address: 'Praça Colombo Guardia, Centro, Alfredo Chaves - ES',
      category: CityPoiCategory.culture,
      latitude: -20.6356507,
      longitude: -40.7484424,
      priority: 8,
      tags: ['artesanato', 'cultura', 'centro'],
    ),
    CityPoiDTO(
      id: 'poi-attraction-sao-roque-de-maravilha',
      name: 'São Roque de Maravilha',
      description:
          'Comunidade do interior citada no Portal de Turismo (vilarejo na região de Maravilha).',
      address: 'São Roque de Maravilha, Alfredo Chaves - ES',
      category: CityPoiCategory.attraction,
      latitude: -20.5536850,
      longitude: -40.8781551,
      priority: 7,
      tags: ['maravilha', 'interior', 'turismo'],
    ),
  ]);

  static final List<CityPoiDTO> _curatedPois = List.unmodifiable(
    _deduplicatePois(
      _rawPois.map(_normalizeBeachCategory),
    ),
  );

  static final List<CityPoiDTO> _googlePois = _buildGooglePoiDtos(
    existingIds: _curatedPois.map((poi) => poi.id).toSet(),
    existingCatalog: _curatedPois,
  );

  static final List<CityPoiDTO> _catalog = List.unmodifiable(
    _deduplicatePois(
      <CityPoiDTO>[
        ..._curatedPois,
        ..._googlePois.map(_normalizeBeachCategory),
      ],
    ),
  );

  static final List<MapRegionDefinition> _regions =
      List.unmodifiable(<MapRegionDefinition>[
    MapRegionDefinition(
      idValue: MapRegionIdValue()..parse('rota_ferradura'),
      labelValue: MapRegionLabelValue()..parse('Rota da Ferradura'),
      center: CityCoordinate(
        latitudeValue: LatitudeValue()..parse('-20.6608'),
        longitudeValue: LongitudeValue()..parse('-40.4915'),
      ),
      zoomValue: MapZoomValue()..parse('14.2'),
    ),
    MapRegionDefinition(
      idValue: MapRegionIdValue()..parse('meaipe'),
      labelValue: MapRegionLabelValue()..parse('Meaípe'),
      center: CityCoordinate(
        latitudeValue: LatitudeValue()..parse('-20.7254'),
        longitudeValue: LongitudeValue()..parse('-40.5198'),
      ),
      zoomValue: MapZoomValue()..parse('14.0'),
    ),
    MapRegionDefinition(
      idValue: MapRegionIdValue()..parse('setiba'),
      labelValue: MapRegionLabelValue()..parse('Setiba'),
      center: CityCoordinate(
        latitudeValue: LatitudeValue()..parse('-20.6392'),
        longitudeValue: LongitudeValue()..parse('-40.4455'),
      ),
      zoomValue: MapZoomValue()..parse('13.6'),
    ),
    MapRegionDefinition(
      idValue: MapRegionIdValue()..parse('nova_guarapari'),
      labelValue: MapRegionLabelValue()..parse('Nova Guarapari'),
      center: CityCoordinate(
        latitudeValue: LatitudeValue()..parse('-20.6965'),
        longitudeValue: LongitudeValue()..parse('-40.5092'),
      ),
      zoomValue: MapZoomValue()..parse('13.8'),
    ),
    MapRegionDefinition(
      idValue: MapRegionIdValue()..parse('alfredo_chaves_centro'),
      labelValue: MapRegionLabelValue()..parse('Alfredo Chaves (Centro)'),
      center: CityCoordinate(
        latitudeValue: LatitudeValue()..parse('-20.6356507'),
        longitudeValue: LongitudeValue()..parse('-40.7484424'),
      ),
      zoomValue: MapZoomValue()..parse('13.8'),
    ),
    MapRegionDefinition(
      idValue: MapRegionIdValue()..parse('alfredo_chaves_matilde'),
      labelValue: MapRegionLabelValue()..parse('Alfredo Chaves (Matilde)'),
      center: CityCoordinate(
        latitudeValue: LatitudeValue()..parse('-20.5562'),
        longitudeValue: LongitudeValue()..parse('-40.8045'),
      ),
      zoomValue: MapZoomValue()..parse('14.4'),
    ),
    MapRegionDefinition(
      idValue: MapRegionIdValue()..parse('alfredo_chaves_cachoeira_alta'),
      labelValue: MapRegionLabelValue()..parse('Alfredo Chaves (Cachoeira Alta)'),
      center: CityCoordinate(
        latitudeValue: LatitudeValue()..parse('-20.668'),
        longitudeValue: LongitudeValue()..parse('-40.785'),
      ),
      zoomValue: MapZoomValue()..parse('14.2'),
    ),
    MapRegionDefinition(
      idValue: MapRegionIdValue()..parse('alfredo_chaves_ibititui'),
      labelValue: MapRegionLabelValue()..parse('Alfredo Chaves (Ibitiruí)'),
      center: CityCoordinate(
        latitudeValue: LatitudeValue()..parse('-20.5997164'),
        longitudeValue: LongitudeValue()..parse('-40.8491966'),
      ),
      zoomValue: MapZoomValue()..parse('14.1'),
    ),
    MapRegionDefinition(
      idValue: MapRegionIdValue()..parse('alfredo_chaves_batatal'),
      labelValue: MapRegionLabelValue()..parse('Alfredo Chaves (Batatal)'),
      center: CityCoordinate(
        latitudeValue: LatitudeValue()..parse('-20.594081'),
        longitudeValue: LongitudeValue()..parse('-40.7596686'),
      ),
      zoomValue: MapZoomValue()..parse('14.1'),
    ),
    MapRegionDefinition(
      idValue: MapRegionIdValue()..parse('alfredo_chaves_crubixa'),
      labelValue: MapRegionLabelValue()..parse('Alfredo Chaves (Crubixá)'),
      center: CityCoordinate(
        latitudeValue: LatitudeValue()..parse('-20.6644246'),
        longitudeValue: LongitudeValue()..parse('-40.9015559'),
      ),
      zoomValue: MapZoomValue()..parse('13.8'),
    ),
  ]);

  static const String _eventFallbackImage =
      'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?w=800';

  List<MapRegionDefinition> availableRegions() => _regions;

  String eventFallbackImage() => _eventFallbackImage;
  List<CityPoiDTO> findPois({PoiQuery query = const PoiQuery()}) {
    final searchTerm = query.searchTerm?.trim().toLowerCase();
    return _catalog.where((poi) {
      if (searchTerm != null && searchTerm.isNotEmpty) {
        final matchesText = poi.name.toLowerCase().contains(searchTerm) ||
            poi.description.toLowerCase().contains(searchTerm) ||
            poi.tags.any(
              (tag) => tag.toLowerCase().contains(searchTerm),
            );
        if (!matchesText) {
          return false;
        }
      }
      if (!query.matchesCategory(poi.category)) {
        return false;
      }
      if (!query.matchesTags(poi.tags)) {
        return false;
      }
      if (query.hasBounds) {
        final coordinate = CityCoordinate(
          latitudeValue: LatitudeValue()..parse(poi.latitude.toString()),
          longitudeValue: LongitudeValue()..parse(poi.longitude.toString()),
        );
        if (!query.containsCoordinate(coordinate)) {
          return false;
        }
      }
      return true;
    }).toList(growable: false);
  }

  PoiFilterOptions availableFilters() {
    final Map<CityPoiCategory, Set<String>> mapping = {};
    for (final poi in _catalog) {
      final set = mapping.putIfAbsent(
        poi.category,
        () => <String>{},
      );
      set.addAll(poi.tags);
    }

    final categories = mapping.entries
        .map(
          (entry) => PoiFilterCategory(
            category: entry.key,
            tags: entry.value,
          ),
        )
        .toList(growable: false);

    return PoiFilterOptions(categories: categories);
  }

  List<MainFilterOption> availableMainFilters() {
    return const <MainFilterOption>[
      MainFilterOption(
        id: 'main_filter_promotions',
        label: 'Promocoes',
        iconName: 'local_offer',
        type: MainFilterType.promotions,
        behavior: MainFilterBehavior.quickApply,
        categories: <CityPoiCategory>{CityPoiCategory.sponsor},
      ),
      MainFilterOption(
        id: 'main_filter_events',
        label: 'Eventos',
        iconName: 'event',
        type: MainFilterType.events,
        behavior: MainFilterBehavior.opensPanel,
      ),
      MainFilterOption(
        id: 'main_filter_music',
        label: 'Musica',
        iconName: 'music_note',
        type: MainFilterType.music,
        behavior: MainFilterBehavior.opensPanel,
        metadata: <String, dynamic>{'eventSlug': 'show'},
      ),
      MainFilterOption(
        id: 'main_filter_regions',
        label: 'Regioes',
        iconName: 'map',
        type: MainFilterType.regions,
        behavior: MainFilterBehavior.opensPanel,
      ),
      MainFilterOption(
        id: 'main_filter_cuisines',
        label: 'Gastronomia',
        iconName: 'restaurant',
        type: MainFilterType.cuisines,
        behavior: MainFilterBehavior.opensPanel,
        metadata: <String, dynamic>{
          'highlightCategory': CityPoiCategory.restaurant,
        },
      ),
    ];
  }

  static List<CityPoiDTO> _buildGooglePoiDtos({
    required Set<String> existingIds,
    required List<CityPoiDTO> existingCatalog,
  }) {
    final usedIds = <String>{...existingIds};
    final normalizedCategoryIndex = <String, CityPoiCategory>{
      for (final poi in existingCatalog) _normalizeName(poi.name): poi.category,
    };
    final seenNames =
        normalizedCategoryIndex.keys.where((name) => name.isNotEmpty).toSet();
    final List<CityPoiDTO> googleEntries = <CityPoiDTO>[];
    for (var index = 0; index < poisGoogleData.length; index++) {
      final data = poisGoogleData[index];
      final rawName = (data['name'] as String?)?.trim();
      final latitude = (data['latitude'] as num?)?.toDouble();
      final longitude = (data['longitude'] as num?)?.toDouble();
      if (rawName == null ||
          rawName.isEmpty ||
          latitude == null ||
          longitude == null) {
        continue;
      }
      final normalizedName = _normalizeName(rawName);
      if (normalizedName.isNotEmpty && seenNames.contains(normalizedName)) {
        continue;
      }
      if (normalizedName.isNotEmpty) {
        seenNames.add(normalizedName);
      }
      final poiId = _buildGooglePoiId(rawName, usedIds, index);
      usedIds.add(poiId);
      final description = (data['description'] as String?)?.trim();
      final duplicatedCategory = normalizedCategoryIndex[normalizedName];
      final poi = CityPoiDTO(
        id: poiId,
        name: rawName,
        description: (description != null && description.isNotEmpty)
            ? description
            : 'Ponto recomendado pelo catálogo Google.',
        address: _resolveAddress(data),
        category: _inferCategory(data, duplicatedCategory: duplicatedCategory),
        latitude: latitude,
        longitude: longitude,
        tags: _buildTags(data),
      );
      googleEntries.add(poi);
    }
    return List<CityPoiDTO>.unmodifiable(googleEntries);
  }

  static String _buildGooglePoiId(
    String name,
    Set<String> existing,
    int index,
  ) {
    String slug = name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');
    slug =
        slug.replaceAll(RegExp(r'-{2,}'), '-').replaceAll(RegExp(r'^-|-$'), '');
    if (slug.isEmpty) {
      slug = 'poi-${index + 1}';
    }
    var candidate = 'poi-google-$slug';
    var suffix = 1;
    while (existing.contains(candidate)) {
      candidate = 'poi-google-$slug-$suffix';
      suffix += 1;
    }
    return candidate;
  }

  static String _resolveAddress(Map<String, dynamic> data) {
    final address = (data['address'] as String?)?.trim();
    if (address != null && address.isNotEmpty) {
      return address;
    }
    final borough = (data['borough'] as String?)?.trim();
    if (borough != null && borough.isNotEmpty) {
      return borough;
    }
    return 'Guarapari';
  }

  static List<String> _buildTags(Map<String, dynamic> data) {
    final tags = <String>{};
    void addValues(String? raw) {
      if (raw == null || raw.trim().isEmpty) {
        return;
      }
      final parts = raw.split(',');
      for (final part in parts) {
        final value = part.trim().toLowerCase();
        if (value.isNotEmpty) {
          tags.add(value);
        }
      }
    }

    addValues(data['subtypes'] as String?);
    addValues(data['category'] as String?);
    addValues(data['borough'] as String?);

    final rating = data['rating'];
    if (rating is num) {
      tags.add('rating-${rating.toStringAsFixed(1)}');
    }

    return List<String>.unmodifiable(tags);
  }

  static CityPoiCategory _inferCategory(
    Map<String, dynamic> data, {
    CityPoiCategory? duplicatedCategory,
  }) {
    if (duplicatedCategory == CityPoiCategory.beach) {
      return CityPoiCategory.beach;
    }
    final category = (data['category'] as String?)?.toLowerCase() ?? '';
    final subtypes = (data['subtypes'] as String?)?.toLowerCase() ?? '';
    final name = (data['name'] as String?)?.toLowerCase() ?? '';
    bool containsAny(String source, List<String> probes) =>
        probes.any((probe) => source.contains(probe));
    final combined = '$category $subtypes $name';

    if (containsAny(combined, const ['hotel', 'lodging', 'pousada', 'inn'])) {
      return CityPoiCategory.lodging;
    }
    if (containsAny(combined, const ['beach', 'praia'])) {
      return CityPoiCategory.beach;
    }
    if (containsAny(
        subtypes, const ['park', 'ecological', 'trail', 'nature'])) {
      return CityPoiCategory.nature;
    }
    if (containsAny(combined, const [
      'restaurant',
      'restaurante',
      'bar',
      'pub',
      'cafe',
      'coffee',
      'padaria',
      'bakery',
      'lanchonete',
      'hamburgueria',
      'sorveteria',
      'delicatessen',
      'chocolate',
      'massa',
      'sushi',
    ])) {
      return CityPoiCategory.restaurant;
    }
    if (containsAny(combined, const ['church', 'igreja'])) {
      return CityPoiCategory.church;
    }
    if (containsAny(combined, const ['event', 'cultural'])) {
      return CityPoiCategory.culture;
    }
    return CityPoiCategory.attraction;
  }

  static String _normalizeName(String name) {
    final stripped = _stripDiacritics(name.toLowerCase());
    return stripped.replaceAll(RegExp(r'[^a-z0-9]+'), '');
  }

  static CityPoiDTO _normalizeBeachCategory(CityPoiDTO poi) {
    if (poi.category == CityPoiCategory.beach || !_looksLikeBeach(poi)) {
      return poi;
    }
    return CityPoiDTO(
      id: poi.id,
      name: poi.name,
      description: poi.description,
      address: poi.address,
      category: CityPoiCategory.beach,
      latitude: poi.latitude,
      longitude: poi.longitude,
      assetPath: poi.assetPath,
      isDynamic: poi.isDynamic,
      movementRadiusMeters: poi.movementRadiusMeters,
      tags: poi.tags,
      priority: poi.priority,
    );
  }

  static bool _looksLikeBeach(CityPoiDTO poi) {
    bool containsBeach(String text) {
      final normalized = _stripDiacritics(text.toLowerCase());
      return normalized.contains('praia') || normalized.contains('beach');
    }

    if (containsBeach(poi.name)) {
      return true;
    }
    if (poi.description.isNotEmpty && containsBeach(poi.description)) {
      return true;
    }
    return false;
  }

  static List<CityPoiDTO> _deduplicatePois(Iterable<CityPoiDTO> pois) {
    final result = <CityPoiDTO>[];
    final seen = <String>{};
    for (final poi in pois) {
      final key = _normalizeName(poi.name);
      if (key.isEmpty || seen.add(key)) {
        result.add(poi);
      }
    }
    return result;
  }

  static String _stripDiacritics(String input) {
    const replacements = <String, String>{
      'á': 'a',
      'à': 'a',
      'â': 'a',
      'ã': 'a',
      'ä': 'a',
      'ç': 'c',
      'é': 'e',
      'è': 'e',
      'ê': 'e',
      'ë': 'e',
      'í': 'i',
      'ì': 'i',
      'î': 'i',
      'ï': 'i',
      'ñ': 'n',
      'ó': 'o',
      'ò': 'o',
      'ô': 'o',
      'õ': 'o',
      'ö': 'o',
      'ú': 'u',
      'ù': 'u',
      'û': 'u',
      'ü': 'u',
      'ý': 'y',
      'ÿ': 'y',
    };
    final buffer = StringBuffer();
    for (final char in input.split('')) {
      buffer.write(replacements[char] ?? char);
    }
    return buffer.toString();
  }
}

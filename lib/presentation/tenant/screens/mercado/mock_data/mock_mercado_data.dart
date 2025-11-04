import 'package:belluga_now/presentation/tenant/screens/mercado/models/mercado_producer.dart';
import 'package:flutter/material.dart';

const mockMercadoCategories = <MercadoCategory>[
  MercadoCategory(
    id: 'queijos',
    label: 'Queijos',
    icon: Icons.breakfast_dining,
  ),
  MercadoCategory(
    id: 'cafe',
    label: 'Caf\u00e9',
    icon: Icons.coffee,
  ),
  MercadoCategory(
    id: 'vinhos',
    label: 'Vinhos',
    icon: Icons.wine_bar,
  ),
  MercadoCategory(
    id: 'artesanato',
    label: 'Artesanato',
    icon: Icons.handyman,
  ),
  MercadoCategory(
    id: 'doces',
    label: 'Doces',
    icon: Icons.icecream,
  ),
  MercadoCategory(
    id: 'hortifruti',
    label: 'Hortifruti',
    icon: Icons.eco,
  ),
];

const mockMercadoProducers = <MercadoProducer>[
  MercadoProducer(
    id: 'sitio-do-cafe-feliz',
    name: 'S\u00edtio do Caf\u00e9 Feliz',
    tagline: 'Caf\u00e9s especiais e produtos da ro\u00e7a',
    address: 'Praia do Morro, Guarapari',
    categories: ['cafe', 'doces'],
    heroImageUrl:
        'https://images.unsplash.com/photo-1504639725590-34d0984388bd?auto=format&fit=crop&w=1200&q=80',
    logoImageUrl:
        'https://images.unsplash.com/photo-1511920170033-f8396924c348?auto=format&fit=crop&w=400&q=80',
    about:
        'Somos uma fam\u00edlia apaixonada por caf\u00e9. Plantamos, colhemos e torramos gr\u00e3os especiais em pequenos lotes para preservar aromas \u00fanicos. Tamb\u00e9m oferecemos doces caseiros preparados com ingredientes vindos da nossa horta.',
    whatsappNumber: '+55 27 99999-1234',
    products: [
      MercadoProduct(
        id: 'cafe-moca',
        name: 'Caf\u00e9 Moca Torrado',
        description:
            'Gr\u00e3os 100% ar\u00e1bica com notas de chocolate e caramelo.',
        imageUrl:
            'https://images.unsplash.com/photo-1447933601403-0c6688de566e?auto=format&fit=crop&w=600&q=80',
      ),
      MercadoProduct(
        id: 'geleia-goiaba',
        name: 'Geleia de Goiaba',
        description:
            'Produzida com frutas da esta\u00e7\u00e3o e sem conservantes.',
        imageUrl:
            'https://images.unsplash.com/photo-1568152950566-c1bf43f4ab28?auto=format&fit=crop&w=600&q=80',
      ),
      MercadoProduct(
        id: 'biscoito-polvilho',
        name: 'Biscoito de Polvilho',
        description: 'Receita da v\u00f3 Dona Nena, leve e crocante.',
        imageUrl:
            'https://images.unsplash.com/photo-1548943487-a2e4e43b4853?auto=format&fit=crop&w=600&q=80',
      ),
    ],
    galleryImages: [
      'https://images.unsplash.com/photo-1504753793650-d4a2b783c15e?auto=format&fit=crop&w=600&q=80',
      'https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?auto=format&fit=crop&w=600&q=80',
      'https://images.unsplash.com/photo-1485808191679-5f86510681a2?auto=format&fit=crop&w=600&q=80',
      'https://images.unsplash.com/photo-1509042239860-f550ce710b93?auto=format&fit=crop&w=600&q=80',
    ],
  ),
  MercadoProducer(
    id: 'vinicola-aurora-do-sol',
    name: 'Vin\u00edcola Aurora do Sol',
    tagline: 'Vinhedos capixabas com alma italiana',
    address: 'Vale Verde, Domingos Martins',
    categories: ['vinhos', 'queijos', 'artesanato'],
    heroImageUrl:
        'https://images.unsplash.com/photo-1510626176961-4b37d0f0b4b0?auto=format&fit=crop&w=1200&q=80',
    logoImageUrl:
        'https://images.unsplash.com/photo-1527169402691-feff5539e52c?auto=format&fit=crop&w=400&q=80',
    about:
        'Fundada pela fam\u00edlia Bianchi h\u00e1 tr\u00eas gera\u00e7\u00f5es, a Aurora do Sol celebra a tradi\u00e7\u00e3o vitivin\u00edcola com uvas cultivadas na serra. Oferecemos degustas\u00e7\u00f5es guiadas, queijos artesanais e uma loja cheia de presentes locais.',
    whatsappNumber: null,
    products: [
      MercadoProduct(
        id: 'vinho-merlot',
        name: 'Merlot Safra 2021',
        description:
            'Vinho tinto elegante com notas de frutas vermelhas e especiarias.',
        imageUrl:
            'https://images.unsplash.com/photo-1543248939-ff40856f65d4?auto=format&fit=crop&w=600&q=80',
      ),
      MercadoProduct(
        id: 'queijo-serra',
        name: 'Queijo da Serra Curado',
        description: 'Maturado por 60 dias, textura macia e sabor marcante.',
        imageUrl:
            'https://images.unsplash.com/photo-1603035002234-3cc62a0833c6?auto=format&fit=crop&w=600&q=80',
      ),
      MercadoProduct(
        id: 'cesta-presentes',
        name: 'Cesta Presente Aurora',
        description: 'Inclui vinhos selecionados, geleias e artesanato local.',
        imageUrl:
            'https://images.unsplash.com/photo-1600185365483-26d7a4cc7519?auto=format&fit=crop&w=600&q=80',
      ),
    ],
    galleryImages: [
      'https://images.unsplash.com/photo-1510626176961-4b37d0f0b4b0?auto=format&fit=crop&w=600&q=80',
      'https://images.unsplash.com/photo-1533488765986-dfa2a9939acd?auto=format&fit=crop&w=600&q=80',
      'https://images.unsplash.com/photo-1524592094714-0f0654e20314?auto=format&fit=crop&w=600&q=80',
      'https://images.unsplash.com/photo-1497534446932-c925b458314e?auto=format&fit=crop&w=600&q=80',
    ],
  ),
  MercadoProducer(
    id: 'atelier-da-serra',
    name: 'Ateli\u00ea da Serra',
    tagline: 'Arte e design com identidade capixaba',
    address: 'Centro, Santa Teresa',
    categories: ['artesanato', 'hortifruti'],
    heroImageUrl:
        'https://images.unsplash.com/photo-1519710164239-da123dc03ef4?auto=format&fit=crop&w=1200&q=80',
    logoImageUrl:
        'https://images.unsplash.com/photo-1479064555552-3ef4979f8908?auto=format&fit=crop&w=400&q=80',
    about:
        'O Ateli\u00ea da Serra nasceu da parceria entre artes\u00e3os e pequenos agricultores. Al\u00e9m de pe\u00e7as feitas \u00e0 m\u00e3o, oferecemos arranjos, temperos e hortali\u00e7as cultivadas em hortas agroecol\u00f3gicas.',
    whatsappNumber: '+55 27 98888-4321',
    products: [
      MercadoProduct(
        id: 'ceramica-autor',
        name: 'Cole\u00e7\u00e3o Cer\u00e2mica da Mata',
        description:
            'Pe\u00e7as \u00fanicas com esmalta\u00e7\u00f5es inspiradas na flora local.',
        imageUrl:
            'https://images.unsplash.com/photo-1519710164239-da123dc03ef4?auto=format&fit=crop&w=600&q=80',
      ),
      MercadoProduct(
        id: 'erva-mate',
        name: 'Erva-mate Artesanal',
        description: 'Secagem natural e blend exclusivo para chimarr\u00e3o.',
        imageUrl:
            'https://images.unsplash.com/photo-1470246973918-29a93221c455?auto=format&fit=crop&w=600&q=80',
      ),
      MercadoProduct(
        id: 'arranjo-floral',
        name: 'Arranjos Florais Vivos',
        description:
            'Composi\u00e7\u00f5es com plantas nativas cultivadas sem agrot\u00f3xicos.',
        imageUrl:
            'https://images.unsplash.com/photo-1487412912498-0447578fcca8?auto=format&fit=crop&w=600&q=80',
      ),
    ],
    galleryImages: [
      'https://images.unsplash.com/photo-1523413363574-c30aa1c2a516?auto=format&fit=crop&w=600&q=80',
      'https://images.unsplash.com/photo-1505576751138-141a9625f92d?auto=format&fit=crop&w=600&q=80',
      'https://images.unsplash.com/photo-1517486808906-6ca8b3f04846?auto=format&fit=crop&w=600&q=80',
      'https://images.unsplash.com/photo-1466978913421-dad2ebd01d17?auto=format&fit=crop&w=600&q=80',
    ],
  ),
];

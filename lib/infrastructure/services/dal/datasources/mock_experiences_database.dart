import 'package:belluga_now/domain/experiences/experience_model.dart';

class MockExperiencesDatabase {
  const MockExperiencesDatabase();

  List<ExperienceModel> get experiences => List.unmodifiable(_experiences);

  ExperienceModel? findById(String id) {
    for (final experience in _experiences) {
      if (experience.id == id) {
        return experience;
      }
    }
    return null;
  }

  static final List<ExperienceModel> _experiences = [
    ExperienceModel(
      id: 'sunrise-outrigger',
      title: 'Passeio de Canoa Havaiana ao Nascer do Sol',
      category: 'Aventura',
      providerName: 'Aventuras do Mar',
      providerId: 'aventuras-do-mar',
      description:
          'Remada guiada ao amanhecer com parada para mergulho em aguas cristalinas. Inclui briefing de seguranca, equipamento completo e registro fotografico.',
      imageUrl:
          'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?w=900',
      duration: '2h30',
      priceLabel: 'R\$ 189 por pessoa',
      meetingPoint: 'Praia das Castanheiras - Quiosque 7',
      highlightItems: [
        'Grupo reduzido (max. 8 pessoas)',
        'Guia bilingue credenciado',
        'Fotos profissionais incluidas',
      ],
    ),
    ExperienceModel(
      id: 'coffee-route',
      title: 'Roteiro Gastronomico: Sabores de Guarapari',
      category: 'Gastronomia',
      providerName: 'Foodies na Estrada',
      providerId: 'foodies-na-estrada',
      description:
          'Tour guiado por cafeterias e restaurantes autorais com curadoria de harmonizacoes. Degustacoes acompanhadas de storytelling dos chefs locais.',
      imageUrl:
          'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=900',
      duration: '3h',
      priceLabel: 'R\$ 149 por pessoa',
      meetingPoint: 'Praca Philomeno Pereira Ribeiro',
      highlightItems: [
        'Inclui 4 paradas gastronomicas',
        'Opcoes vegetarianas em todas as etapas',
        'Voucher de desconto em parceiros do roteiro',
      ],
    ),
    ExperienceModel(
      id: 'morro-photo-safari',
      title: 'Photo Safari: Por do Sol na Praia do Morro',
      category: 'Natureza',
      providerName: 'Lens & Trails',
      providerId: 'lens-and-trails',
      description:
          'Expedicao fotografica ao entardecer com guia especializado em fotografia mobile. Aula pratica, melhores angulos e edicao rapido direto no celular.',
      imageUrl:
          'https://images.unsplash.com/photo-1500534314209-a25ddb2bd429?w=900',
      duration: '2h',
      priceLabel: 'R\$ 129 por pessoa',
      meetingPoint: 'Mirante da Praia do Morro',
      highlightItems: [
        'Tripes e filtros inclusos',
        'Workshop rapido de fotografia com smartphone',
        'Entrega de presets exclusivos',
      ],
    ),
    ExperienceModel(
      id: 'secret-waterfalls',
      title: 'Trilha Privada: Cachoeiras Secretas',
      category: 'Natureza',
      providerName: 'Guia Clara Nunes',
      providerId: 'clara-nunes',
      description:
          'Trilha nivel moderado pela mata atlantica culminando em um circuito de cachoeiras exclusivas. Inclui picnic artesanal e transporte 4x4.',
      imageUrl:
          'https://images.unsplash.com/photo-1431794062232-2a99a5431c6c?w=900',
      duration: '4h',
      priceLabel: 'R\$ 249 por pessoa',
      meetingPoint: 'Ponto de apoio Belluga Now',
      highlightItems: [
        'Seguro aventura incluso',
        'Picnic com produtos de produtores locais',
        'Registro em video 4K entregue por link',
      ],
    ),
    ExperienceModel(
      id: 'music-boat',
      title: 'Sunset Boat com Musica Ao Vivo',
      category: 'Noite',
      providerName: 'Mare Alta Entertainment',
      providerId: 'mare-alta',
      description:
          'Passeio de barco ao por do sol com DJ convidado, pista intima e bar tematico. Navegacao pela Orla Azul com parada para mergulho ao anoitecer.',
      imageUrl:
          'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?w=900',
      duration: '3h30',
      priceLabel: 'R\$ 289 por pessoa',
      meetingPoint: 'Marina Enseada Azul',
      highlightItems: [
        'Welcome drink autoral',
        'Line-up rotativo com artistas locais',
        'Transfer opcional disponivel',
      ],
    ),
  ];
}


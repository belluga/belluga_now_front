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
      tags: [
        'canoa havaiana',
        'nascer do sol',
        'oceano calmo',
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
      tags: [
        'tour gastronomico',
        'cafes autorais',
        'historia local',
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
      tags: [
        'fotografia',
        'por do sol',
        'praia do morro',
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
      tags: [
        'trilha guiada',
        'cachoeira exclusiva',
        'mata atlantica',
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
      tags: [
        'boat party',
        'dj ao vivo',
        'sunset',
      ],
    ),
    ExperienceModel(
      id: 'reef-snorkel-safari',
      title: 'Safari de Snorkel nos Recifes Rasos',
      category: 'Oceano',
      providerName: 'Guia Nereida',
      providerId: 'guia-nereida',
      description:
          'Exploracao guiada aos recifes costeiros com snorkel completo, briefings sobre fauna marinha e suporte de seguranca em lancha de apoio.',
      imageUrl:
          'https://images.unsplash.com/photo-1505761671935-60b3a7427bad?w=900',
      duration: '3h',
      priceLabel: 'R\$ 210 por pessoa',
      meetingPoint: 'Ponto de embarque Praia do Meio',
      highlightItems: [
        'Equipamentos higienizados inclusos',
        'Flutuadores individuais e colete salva-vidas',
        'Registro de fotos subaquaticas entregue por link',
      ],
      tags: [
        'snorkel',
        'recife',
        'vida marinha',
      ],
    ),
    ExperienceModel(
      id: 'bioluminescencia-night-tour',
      title: 'Remada Noturna Bioluminescente',
      category: 'Oceano',
      providerName: 'Ocean Stories',
      providerId: 'ocean-stories',
      description:
          'Passeio noturno em caiaques transparentes para vivenciar o brilho bioluminescente em enseada protegida, guiado por biologos locais.',
      imageUrl:
          'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=900',
      duration: '2h',
      priceLabel: 'R\$ 260 por pessoa',
      meetingPoint: 'Base flutuante Enseada Azul',
      highlightItems: [
        'Caiaques duplos transparentes',
        'Apresentacao sobre bioluminescencia antes da remada',
        'Cha hibisco quente ao final',
      ],
      tags: [
        'experiencia noturna',
        'bioluminescencia',
        'caiaque',
      ],
    ),
    ExperienceModel(
      id: 'shipwreck-dive',
      title: 'Mergulho em Naufragio na Ilha Rasgada',
      category: 'Oceano',
      providerName: 'Aqua Explorers',
      providerId: 'aqua-explorers',
      description:
          'Saida de mergulho autonomo para certificacao open water em naufragio historico, com instrutor dedicado e briefings de seguranca completos.',
      imageUrl:
          'https://images.unsplash.com/photo-1544552866-0b660abd7f53?w=900',
      duration: '4h',
      priceLabel: 'R\$ 490 por pessoa',
      meetingPoint: 'Marina Porto Grande',
      highlightItems: [
        'Cilindro adicional incluso',
        'Equipamento premium Scubapro',
        'Guia submarino fotografo credenciado',
      ],
      tags: [
        'mergulho autonomo',
        'naufragio',
        'aventureiros',
      ],
    ),
    ExperienceModel(
      id: 'standup-yoga-dawn',
      title: 'Yoga ao Nascer do Sol em Stand-Up Paddle',
      category: 'Oceano',
      providerName: 'Flow Ocean Studio',
      providerId: 'flow-ocean',
      description:
          'Sequencia de yoga guiada sobre pranchas de stand-up paddle em baia protegida, seguida de meditacao guiada e smoothie funcional.',
      imageUrl:
          'https://images.unsplash.com/photo-1517832207067-4db24a2ae47c?w=900',
      duration: '1h45',
      priceLabel: 'R\$ 180 por pessoa',
      meetingPoint: 'Deck de madeira Beira Mar',
      highlightItems: [
        'Pranchas estaveis e ancorage com elos',
        'Instrutora certificada em yoga aquatica',
        'Smoothie funcional pos pratica',
      ],
      tags: [
        'stand-up paddle',
        'yoga',
        'bem-estar',
      ],
    ),
    ExperienceModel(
      id: 'coastal-sailing-picnic',
      title: 'Velejada Costeira com Picnic Gourmet',
      category: 'Oceano',
      providerName: 'Capitao Lipe Experiencias',
      providerId: 'capitao-lipe',
      description:
          'Passeio em veleiro de 38 pes pela costa de Guarapari com paradas em enseadas exclusivas e picnic gourmet com ingredientes locais.',
      imageUrl:
          'https://images.unsplash.com/photo-1500375592092-40eb2168fd21?w=900',
      duration: '5h',
      priceLabel: 'R\$ 560 por casal',
      meetingPoint: 'Pier central Guarapari',
      highlightItems: [
        'Capitao com 20 anos de experiencia',
        'Picnic com queijos artesanais e espumante capixaba',
        'Kit snorkel a bordo',
      ],
      tags: [
        'veleiro',
        'romantico',
        'gastronomia local',
      ],
    ),
    ExperienceModel(
      id: 'full-moon-paddle',
      title: 'Remada de Lua Cheia com Fogos Frios',
      category: 'Oceano',
      providerName: 'Guarapari Paddle Club',
      providerId: 'guarapari-paddle',
      description:
          'Cortejo de stand-up paddle iluminado por lanternas LED sob a lua cheia, com encerramento em praia isolada e fogos frios controlados.',
      imageUrl:
          'https://images.unsplash.com/photo-1493558103817-58b2924bce98?w=900',
      duration: '2h30',
      priceLabel: 'R\$ 230 por pessoa',
      meetingPoint: 'Clube de Remo Canal Azul',
      highlightItems: [
        'Lanternas LED e colete refletivo inclusos',
        'Equipe de apoio em lancha motorizada',
        'Cacao quente com especiarias ao final',
      ],
      tags: [
        'lua cheia',
        'stand-up paddle',
        'remada noturna',
      ],
    ),
    ExperienceModel(
      id: 'mangrove-kayak-expedition',
      title: 'Expedicao de Caiaque pelo Mangue Azul',
      category: 'Oceano',
      providerName: 'Mangue Vivo',
      providerId: 'mangue-vivo',
      description:
          'Remada interpretativa por tuneis de manguezal com guia ambiental, birdwatching e parada para degustacao de ostras frescas.',
      imageUrl:
          'https://images.unsplash.com/photo-1457068975672-67c0b5e102f1?w=900',
      duration: '3h30',
      priceLabel: 'R\$ 210 por pessoa',
      meetingPoint: 'Centro de interpretacao Mangue Azul',
      highlightItems: [
        'Caiaques sit-on-top duplos com compartimento seco',
        'Binoculos e guia de aves inclusos',
        'Degustacao de ostras com vinagrete de maracuja',
      ],
      tags: [
        'manguezal',
        'caiaque',
        'gastronomia do mar',
      ],
    ),
    ExperienceModel(
      id: 'marine-photo-workshop',
      title: 'Workshop de Fotografia Marinha Free Diver',
      category: 'Oceano',
      providerName: 'Lens Reef Academy',
      providerId: 'lens-reef',
      description:
          'Treinamento intensivo de fotografia marinha para free divers com tecnicas de apneia, composicao subaquatica e edicao rapida.',
      imageUrl:
          'https://images.unsplash.com/photo-1518837695005-2083093ee35b?w=900',
      duration: '6h',
      priceLabel: 'R\$ 620 por pessoa',
      meetingPoint: 'Centro de mergulho Morro Beach',
      highlightItems: [
        'Sessao pratica em piscina antes do mar',
        'Uso de cameras action 4K incluso',
        'Pacote de presets Lightroom para submarino',
      ],
      tags: [
        'fotografia submarina',
        'free dive',
        'treinamento intensivo',
      ],
    ),
    ExperienceModel(
      id: 'tidepool-explorers',
      title: 'Expedicao Kids em Piscinas Naturais',
      category: 'Oceano',
      providerName: 'Ocean Rangers',
      providerId: 'ocean-rangers',
      description:
          'Atividade educativa para criancas com exploracao guiada de piscinas naturais na mare baixa, microscopia portatil e diario de bordo.',
      imageUrl:
          'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?w=900',
      duration: '2h',
      priceLabel: 'R\$ 95 por crianca',
      meetingPoint: 'Base educativa Praia da Areia Preta',
      highlightItems: [
        'Kit explorador com lupa e diario inclusos',
        'Educadores ambientais certificados',
        'Lanche saudavel incluso',
      ],
      tags: [
        'familia',
        'educacao ambiental',
        'mare baixa',
      ],
    ),
    ExperienceModel(
      id: 'reef-cleanup-volunteer',
      title: 'Mutirao de Limpeza dos Recifes Urbanos',
      category: 'Oceano',
      providerName: 'Instituto Mar Limpo',
      providerId: 'instituto-mar-limpo',
      description:
          'Aventura cidada com briefing de impacto, mergulho guiado para coleta de residuos e oficina de reciclagem criativa na base do instituto.',
      imageUrl:
          'https://images.unsplash.com/photo-1494774157365-9e04c6720e47?w=900',
      duration: '5h',
      meetingPoint: 'Sede Instituto Mar Limpo',
      highlightItems: [
        'Equipamento de mergulho e luvas inclusos',
        'Oficina de reciclagem criativa pos mergulho',
        'Certificado digital de voluntariado',
      ],
      tags: [
        'voluntariado',
        'recife urbano',
        'impacto positivo',
      ],
    ),
    ExperienceModel(
      id: 'blue-crab-gastronomy-cruise',
      title: 'Cruzeiro Gastronomico Caranguejo Azul',
      category: 'Oceano',
      providerName: 'Chef Marina Experiencias',
      providerId: 'chef-marina',
      description:
          'Navegacao lenta por canais com degustacao progressiva de pratos a base de caranguejo azul harmonizados com cervejas artesanais locais.',
      imageUrl:
          'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=900',
      duration: '3h',
      priceLabel: 'R\$ 340 por pessoa',
      meetingPoint: 'Cais gastronomico Canal Azul',
      highlightItems: [
        'Menu degustacao com 5 etapas',
        'Harmonizacao com cervejas capixabas',
        'Receituario digital enviado apos o passeio',
      ],
      tags: [
        'gastronomia do mar',
        'caranguejo azul',
        'navegacao gourmet',
      ],
    ),
  ];
}

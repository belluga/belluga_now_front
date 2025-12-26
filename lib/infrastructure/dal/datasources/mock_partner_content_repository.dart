import 'package:belluga_now/domain/partners/partner_model.dart';
import 'package:belluga_now/infrastructure/dal/dto/profile/profile_event_dto.dart';
import 'package:belluga_now/infrastructure/dal/dto/profile/profile_faq_dto.dart';
import 'package:belluga_now/infrastructure/dal/dto/profile/profile_link_dto.dart';
import 'package:belluga_now/infrastructure/dal/dto/profile/profile_location_dto.dart';
import 'package:belluga_now/infrastructure/dal/dto/profile/profile_media_dto.dart';
import 'package:belluga_now/infrastructure/dal/dto/profile/profile_product_dto.dart';
import 'package:belluga_now/infrastructure/dal/dto/profile/profile_score_dto.dart';
import 'package:belluga_now/infrastructure/dal/dto/profile/profile_supported_entity_dto.dart';
import 'package:belluga_now/presentation/tenant/partners/models/partner_profile_config.dart';

class MockPartnerContentRepository {
  MockPartnerContentRepository();

  Map<ProfileModuleId, dynamic> loadModulesForPartner(PartnerModel partner) {
    return switch (partner.type) {
      PartnerType.artist => {
          ProfileModuleId.agendaCarousel: _mockEvents(partner),
          ProfileModuleId.agendaList: _mockEvents(partner),
          ProfileModuleId.musicPlayer: _mockTracks(),
          ProfileModuleId.productGrid: _mockProducts(),
          ProfileModuleId.externalLinks: _mockLinks(),
          ProfileModuleId.socialScore: _mockScore(),
        },
      PartnerType.venue => {
          ProfileModuleId.locationInfo: _mockLocation(partner),
          ProfileModuleId.richText: partner.bio ?? _mockRichText(),
          ProfileModuleId.agendaList: _mockEvents(partner),
          ProfileModuleId.supportedEntities: _mockSupportedEntities(),
          ProfileModuleId.productGrid: _mockProducts(),
          ProfileModuleId.socialScore: _mockScore(),
        },
      PartnerType.experienceProvider => {
          ProfileModuleId.experienceCards: _mockExperiences(),
          ProfileModuleId.richText: _mockRichText(),
          ProfileModuleId.faq: _mockFaq(),
          ProfileModuleId.socialScore: _mockScore(),
        },
      PartnerType.curator => {
          ProfileModuleId.videoGallery: _mockVideos(),
          ProfileModuleId.richText: _mockRichText(),
          ProfileModuleId.externalLinks: _mockLinks(),
          ProfileModuleId.sponsorBanner: _mockSponsor(),
          ProfileModuleId.socialScore: _mockScore(),
        },
      PartnerType.influencer => {
          ProfileModuleId.photoGallery: _mockPhotos(),
          ProfileModuleId.affinityCarousels: _mockRecommendations(),
          ProfileModuleId.agendaList: _mockEvents(partner),
          ProfileModuleId.socialScore: _mockScore(),
        },
    };
  }

  List<ProfileMediaDTO> _mockTracks() =>
      [ProfileMediaDTO(url: 'https://open.spotify.com/track/mock', title: 'Vento Sul')];

  String _mockRichText() => 'Conteúdo institucional e história do parceiro.';

  List<ProfileEventDTO> _mockEvents(PartnerModel partner) {
    return List.generate(
      5,
      (i) => ProfileEventDTO(
        title: 'Evento ${i + 1}',
        date: '15 JAN • 20h',
        location: partner.tags.isNotEmpty ? partner.tags.first : 'Guarapari',
      ),
    );
  }

  List<ProfileProductDTO> _mockProducts() {
    return [
      ProfileProductDTO(
        title: 'Camiseta Tour',
        price: 'R\$ 80',
        image:
            'https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?w=400',
      ),
      ProfileProductDTO(
        title: 'Workshop VIP',
        price: 'R\$ 250',
        image:
            'https://images.unsplash.com/photo-1515165562835-c3b8c1c7c3c4?w=400',
      ),
      ProfileProductDTO(
        title: 'Livro Autografado',
        price: 'R\$ 60',
        image:
            'https://images.unsplash.com/photo-1524995997946-a1c2e315a42f?w=400',
      ),
      ProfileProductDTO(
        title: 'Aula Particular',
        price: 'R\$ 180',
        image:
            'https://images.unsplash.com/photo-1448932223592-d1fc686e76ea?w=400',
      ),
    ];
  }

  List<ProfileMediaDTO> _mockPhotos() => List.generate(
        12,
        (i) => ProfileMediaDTO(
          url:
              'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?w=400&sig=$i',
        ),
      );

  List<ProfileMediaDTO> _mockVideos() => List.generate(
        6,
        (i) => ProfileMediaDTO(
          title: 'Vídeo ${i + 1}',
          url:
              'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=400&sig=$i',
        ),
      );

  List<Map<String, String>> _mockExperiences() {
    return [
      {
        'title': 'Batismo de Mergulho',
        'duration': '4h',
        'price': 'R\$ 250'
      },
      {'title': 'Trilha da Pesca', 'duration': '2h', 'price': 'R\$ 80'},
      {'title': 'Passeio de Barco', 'duration': '3h', 'price': 'R\$ 150'},
    ];
  }

  List<ProfileFaqDTO> _mockFaq() => [
        ProfileFaqDTO(
            question: 'Preciso saber nadar?',
            answer: 'Não, temos coletes e guias.'),
        ProfileFaqDTO(
            question: 'Equipamentos inclusos?',
            answer: 'Sim, tudo incluso.'),
        ProfileFaqDTO(
            question: 'Idade mínima?', answer: '12 anos acompanhados.'),
      ];

  ProfileLocationDTO _mockLocation(PartnerModel partner) => ProfileLocationDTO(
        address: 'Rua Central, 123 - Guarapari',
        status: 'Aberto agora • Fecha às 23h',
        lat: (partner.distanceMeters ?? 0).toString(),
        lng: (partner.distanceMeters ?? 0).toString(),
      );

  List<ProfileLinkDTO> _mockLinks() => [
        ProfileLinkDTO(
          title: 'Comprar livro',
          subtitle: 'Link externo',
          icon: 'book',
        ),
        ProfileLinkDTO(
          title: 'Apoiar via PIX',
          subtitle: 'Contribua com o criador',
          icon: 'pix',
        ),
      ];

  List<Map<String, String>> _mockRecommendations() => [
        {'title': 'Cantinho da Moqueca', 'type': 'Restaurante'},
        {'title': 'Melhores Praias', 'type': 'Guia'},
        {'title': 'Trilhas e Mirantes', 'type': 'Passeio'},
      ];

  List<ProfileSupportedEntityDTO> _mockSupportedEntities() => [
        ProfileSupportedEntityDTO(title: 'DJ Alex Beat'),
        ProfileSupportedEntityDTO(title: 'Curadoria ES'),
        ProfileSupportedEntityDTO(title: 'Agenda Cultural'),
      ];

  String _mockSponsor() => 'Cantinho da Moqueca';

  ProfileScoreDTO _mockScore() =>
      ProfileScoreDTO(invites: '1.5k', presences: '850');
}

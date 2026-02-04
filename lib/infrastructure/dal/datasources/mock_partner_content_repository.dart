import 'package:belluga_now/domain/partners/account_profile_model.dart';
import 'package:belluga_now/domain/partners/projections/partner_profile_config.dart';
import 'package:belluga_now/domain/partners/projections/partner_profile_module_data.dart';
import 'package:belluga_now/domain/repositories/partner_profile_content_repository_contract.dart';

class MockPartnerContentRepository
    implements PartnerProfileContentRepositoryContract {
  MockPartnerContentRepository();

  @override
  Map<ProfileModuleId, Object?> loadModulesForPartner(
    AccountProfileModel partner,
  ) {
    return switch (partner.type) {
      'artist' => {
          ProfileModuleId.agendaCarousel: _mockEvents(partner),
          ProfileModuleId.agendaList: _mockEvents(partner),
          ProfileModuleId.richText: partner.bio ?? _mockRichText(),
          ProfileModuleId.musicPlayer: _mockTracks(),
          ProfileModuleId.productGrid: _mockProducts(),
          ProfileModuleId.externalLinks: _mockLinks(),
          ProfileModuleId.socialScore: _mockScore(),
        },
      'venue' => {
          ProfileModuleId.locationInfo: _mockLocation(partner),
          ProfileModuleId.richText: partner.bio ?? _mockRichText(),
          ProfileModuleId.agendaList: _mockEvents(partner),
          ProfileModuleId.supportedEntities: _mockSupportedEntities(),
          ProfileModuleId.productGrid: _mockProducts(),
          ProfileModuleId.socialScore: _mockScore(),
        },
      'experience_provider' => {
          ProfileModuleId.experienceCards: _mockExperiences(),
          ProfileModuleId.richText: _mockRichText(),
          ProfileModuleId.faq: _mockFaq(),
          ProfileModuleId.socialScore: _mockScore(),
        },
      'curator' => {
          ProfileModuleId.videoGallery: _mockVideos(),
          ProfileModuleId.richText: _mockRichText(),
          ProfileModuleId.externalLinks: _mockLinks(),
          ProfileModuleId.sponsorBanner: _mockSponsor(),
          ProfileModuleId.socialScore: _mockScore(),
        },
      'influencer' => {
          ProfileModuleId.photoGallery: _mockPhotos(),
          ProfileModuleId.affinityCarousels: _mockRecommendations(),
          ProfileModuleId.agendaList: _mockEvents(partner),
          ProfileModuleId.socialScore: _mockScore(),
        },
      _ => const <ProfileModuleId, dynamic>{},
    };
  }

  List<PartnerMediaView> _mockTracks() => const [
        PartnerMediaView(
          url: 'https://open.spotify.com/track/mock',
          title: 'Vento Sul',
        ),
      ];

  String _mockRichText() => 'Conteúdo institucional e história do parceiro.';

  List<PartnerEventView> _mockEvents(AccountProfileModel partner) {
    return List.generate(
      5,
      (i) => PartnerEventView(
        title: 'Evento ${i + 1}',
        date: '15 JAN • 20h',
        location: partner.tags.isNotEmpty ? partner.tags.first : 'Guarapari',
      ),
    );
  }

  List<PartnerProductView> _mockProducts() {
    return [
      PartnerProductView(
        title: 'Camiseta Tour',
        price: 'R\$ 80',
        imageUrl:
            'https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?w=400',
      ),
      PartnerProductView(
        title: 'Workshop VIP',
        price: 'R\$ 250',
        imageUrl:
            'https://images.unsplash.com/photo-1515165562835-c3b8c1c7c3c4?w=400',
      ),
      PartnerProductView(
        title: 'Livro Autografado',
        price: 'R\$ 60',
        imageUrl:
            'https://images.unsplash.com/photo-1524995997946-a1c2e315a42f?w=400',
      ),
      PartnerProductView(
        title: 'Aula Particular',
        price: 'R\$ 180',
        imageUrl:
            'https://images.unsplash.com/photo-1448932223592-d1fc686e76ea?w=400',
      ),
    ];
  }

  List<PartnerMediaView> _mockPhotos() => List.generate(
        12,
        (i) => PartnerMediaView(
          url:
              'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?w=400&sig=$i',
        ),
      );

  List<PartnerMediaView> _mockVideos() => List.generate(
        6,
        (i) => PartnerMediaView(
          title: 'Vídeo ${i + 1}',
          url:
              'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=400&sig=$i',
        ),
      );

  List<PartnerExperienceView> _mockExperiences() {
    return const [
      PartnerExperienceView(
        title: 'Batismo de Mergulho',
        duration: '4h',
        price: 'R\$ 250',
      ),
      PartnerExperienceView(
        title: 'Trilha da Pesca',
        duration: '2h',
        price: 'R\$ 80',
      ),
      PartnerExperienceView(
        title: 'Passeio de Barco',
        duration: '3h',
        price: 'R\$ 150',
      ),
    ];
  }

  List<PartnerFaqView> _mockFaq() => [
        PartnerFaqView(
            question: 'Preciso saber nadar?',
            answer: 'Não, temos coletes e guias.'),
        PartnerFaqView(
            question: 'Equipamentos inclusos?',
            answer: 'Sim, tudo incluso.'),
        PartnerFaqView(
            question: 'Idade mínima?', answer: '12 anos acompanhados.'),
      ];

  PartnerLocationView _mockLocation(AccountProfileModel partner) =>
      PartnerLocationView(
        address: 'Rua Central, 123 - Guarapari',
        status: 'Aberto agora • Fecha às 23h',
        lat: (partner.distanceMeters ?? 0).toString(),
        lng: (partner.distanceMeters ?? 0).toString(),
      );

  List<PartnerLinkView> _mockLinks() => [
        PartnerLinkView(
          title: 'Comprar livro',
          subtitle: 'Link externo',
          icon: 'book',
        ),
        PartnerLinkView(
          title: 'Apoiar via PIX',
          subtitle: 'Contribua com o criador',
          icon: 'pix',
        ),
      ];

  List<PartnerRecommendationView> _mockRecommendations() => const [
        PartnerRecommendationView(
          title: 'Cantinho da Moqueca',
          type: 'Restaurante',
        ),
        PartnerRecommendationView(
          title: 'Melhores Praias',
          type: 'Guia',
        ),
        PartnerRecommendationView(
          title: 'Trilhas e Mirantes',
          type: 'Passeio',
        ),
      ];

  List<PartnerSupportedEntityView> _mockSupportedEntities() => [
        PartnerSupportedEntityView(title: 'DJ Alex Beat'),
        PartnerSupportedEntityView(title: 'Curadoria ES'),
        PartnerSupportedEntityView(title: 'Agenda Cultural'),
      ];

  String _mockSponsor() => 'Cantinho da Moqueca';

  PartnerScoreView _mockScore() =>
      const PartnerScoreView(invites: '1.5k', presences: '850');
}

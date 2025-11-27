import 'package:belluga_now/domain/partners/partner_model.dart';
import 'package:belluga_now/presentation/tenant/partners/models/partner_profile_config.dart';

/// Mock database providing profile module data keyed by partner slug.
class MockPartnerProfileDatabase {
  MockPartnerProfileDatabase();

  PartnerProfileConfig buildConfig(PartnerModel partner) {
    switch (partner.type) {
      case PartnerType.artist:
        return PartnerProfileConfig(
          partner: partner,
          tabs: [
            ProfileTabConfig(
              title: 'Destaques',
              modules: [
                ProfileModuleConfig(id: ProfileModuleId.agendaCarousel),
                ProfileModuleConfig(id: ProfileModuleId.musicPlayer),
              ],
            ),
            ProfileTabConfig(
              title: 'Loja & Extras',
              modules: [
                ProfileModuleConfig(id: ProfileModuleId.productGrid),
                ProfileModuleConfig(id: ProfileModuleId.externalLinks),
              ],
            ),
          ],
        );
      case PartnerType.venue:
        return PartnerProfileConfig(
          partner: partner,
          tabs: [
            ProfileTabConfig(
              title: 'O Local',
              modules: [
                ProfileModuleConfig(id: ProfileModuleId.locationInfo),
                ProfileModuleConfig(id: ProfileModuleId.richText, title: 'O Ambiente'),
              ],
            ),
            ProfileTabConfig(
              title: 'Eventos',
              modules: [
                ProfileModuleConfig(id: ProfileModuleId.agendaList),
              ],
            ),
            ProfileTabConfig(
              title: 'Residentes',
              modules: [
                ProfileModuleConfig(id: ProfileModuleId.supportedEntities, title: 'Nossos DJs Residentes'),
              ],
            ),
          ],
        );
      case PartnerType.experienceProvider:
        return PartnerProfileConfig(
          partner: partner,
          tabs: [
            ProfileTabConfig(
              title: 'Experiências',
              modules: [
                ProfileModuleConfig(id: ProfileModuleId.experienceCards),
              ],
            ),
            ProfileTabConfig(
              title: 'Sobre o Guia',
              modules: [
                ProfileModuleConfig(id: ProfileModuleId.richText, title: 'Quem Somos'),
              ],
            ),
            ProfileTabConfig(
              title: 'Dúvidas',
              modules: [
                ProfileModuleConfig(id: ProfileModuleId.faq),
              ],
            ),
          ],
        );
      case PartnerType.curator:
        return PartnerProfileConfig(
          partner: partner,
          tabs: [
            ProfileTabConfig(
              title: 'Acervo',
              modules: [
                ProfileModuleConfig(id: ProfileModuleId.videoGallery),
                ProfileModuleConfig(id: ProfileModuleId.richText, title: 'Artigos Recentes'),
              ],
            ),
            ProfileTabConfig(
              title: 'Sobre & Apoio',
              modules: [
                ProfileModuleConfig(id: ProfileModuleId.richText, title: 'Sobre'),
                ProfileModuleConfig(id: ProfileModuleId.externalLinks),
                ProfileModuleConfig(id: ProfileModuleId.sponsorBanner),
              ],
            ),
          ],
        );
      case PartnerType.influencer:
        return PartnerProfileConfig(
          partner: partner,
          tabs: [
            ProfileTabConfig(
              title: 'Galeria',
              modules: [
                ProfileModuleConfig(id: ProfileModuleId.photoGallery),
              ],
            ),
            ProfileTabConfig(
              title: 'Recomendações',
              modules: [
                ProfileModuleConfig(id: ProfileModuleId.affinityCarousels),
              ],
            ),
            ProfileTabConfig(
              title: 'Próximos rolês',
              modules: [
                ProfileModuleConfig(id: ProfileModuleId.agendaList),
              ],
            ),
          ],
        );
    }
  }
}

import 'package:belluga_now/domain/partners/account_profile_model.dart';
import 'package:belluga_now/domain/partners/profile_type_capabilities.dart';
import 'package:belluga_now/presentation/tenant/partners/models/partner_profile_config.dart';

/// Mock database providing profile module data keyed by partner slug.
class MockPartnerProfileDatabase {
  MockPartnerProfileDatabase();

  PartnerProfileConfig buildConfig(
    AccountProfileModel partner, {
    ProfileTypeCapabilities? capabilities,
  }) {
    if (capabilities != null) {
      final tabs = <ProfileTabConfig>[];
      if (capabilities.hasBio &&
          partner.bio != null &&
          partner.bio!.trim().isNotEmpty) {
        tabs.add(
          ProfileTabConfig(
            title: 'Sobre',
            modules: [
              ProfileModuleConfig(id: ProfileModuleId.richText),
            ],
          ),
        );
      }
      if (capabilities.isPoiEnabled) {
        tabs.add(
          ProfileTabConfig(
            title: 'Como Chegar',
            modules: [
              ProfileModuleConfig(id: ProfileModuleId.locationInfo),
            ],
          ),
        );
      }
      if (capabilities.hasEvents) {
        tabs.add(
          ProfileTabConfig(
            title: 'Próximos Eventos',
            modules: [
              ProfileModuleConfig(id: ProfileModuleId.agendaList),
            ],
          ),
        );
      }
      return PartnerProfileConfig(
        partner: partner,
        tabs: tabs,
      );
    }

    switch (partner.type) {
      case 'artist':
        final hasBio = partner.bio != null && partner.bio!.trim().isNotEmpty;
        final tabs = <ProfileTabConfig>[];
        if (hasBio) {
          tabs.add(
            ProfileTabConfig(
              title: 'Sobre',
              modules: [
                ProfileModuleConfig(id: ProfileModuleId.richText),
              ],
            ),
          );
        }
        tabs.add(
          ProfileTabConfig(
            title: 'Agenda',
            modules: [
              ProfileModuleConfig(id: ProfileModuleId.agendaList),
            ],
          ),
        );
        return PartnerProfileConfig(
          partner: partner,
          tabs: tabs,
        );
      case 'venue':
        final hasBio = partner.bio != null && partner.bio!.trim().isNotEmpty;
        final tabs = <ProfileTabConfig>[];
        if (hasBio) {
          tabs.add(
            ProfileTabConfig(
              title: 'Sobre',
              modules: [
                ProfileModuleConfig(id: ProfileModuleId.richText),
              ],
            ),
          );
        }
        tabs.addAll([
          ProfileTabConfig(
            title: 'Como Chegar',
            modules: [
              ProfileModuleConfig(id: ProfileModuleId.locationInfo),
            ],
          ),
          ProfileTabConfig(
            title: 'Eventos',
            modules: [
              ProfileModuleConfig(id: ProfileModuleId.agendaList),
            ],
          ),
        ]);
        return PartnerProfileConfig(
          partner: partner,
          tabs: tabs,
        );
      case 'experience_provider':
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
      case 'curator':
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
      case 'influencer':
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
      default:
        return PartnerProfileConfig(
          partner: partner,
          tabs: const [],
        );
    }
  }
}

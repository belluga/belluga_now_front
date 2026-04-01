import 'package:belluga_now/domain/partners/account_profile_model.dart';
import 'package:belluga_now/domain/partners/profile_type_capabilities.dart';
import 'package:belluga_now/domain/partners/projections/partner_profile_config.dart';
import 'package:belluga_now/domain/partners/projections/value_objects/partner_projection_text_values.dart';

/// Builds profile module configuration based on partner type and capabilities.
class PartnerProfileConfigBuilder {
  PartnerProfileConfigBuilder();

  PartnerProfileConfig build(
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
            titleValue: partnerProjectionRequiredText('Sobre'),
            modules: [
              ProfileModuleConfig(id: ProfileModuleId.richText),
            ],
          ),
        );
      }
      if (capabilities.isPoiEnabled) {
        tabs.add(
          ProfileTabConfig(
            titleValue: partnerProjectionRequiredText('Como Chegar'),
            modules: [
              ProfileModuleConfig(id: ProfileModuleId.locationInfo),
            ],
          ),
        );
      }
      if (capabilities.hasEvents) {
        tabs.add(
          ProfileTabConfig(
            titleValue: partnerProjectionRequiredText('Próximos Eventos'),
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
              titleValue: partnerProjectionRequiredText('Sobre'),
              modules: [
                ProfileModuleConfig(id: ProfileModuleId.richText),
              ],
            ),
          );
        }
        tabs.add(
          ProfileTabConfig(
            titleValue: partnerProjectionRequiredText('Agenda'),
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
              titleValue: partnerProjectionRequiredText('Sobre'),
              modules: [
                ProfileModuleConfig(id: ProfileModuleId.richText),
              ],
            ),
          );
        }
        tabs.addAll([
          ProfileTabConfig(
            titleValue: partnerProjectionRequiredText('Como Chegar'),
            modules: [
              ProfileModuleConfig(id: ProfileModuleId.locationInfo),
            ],
          ),
          ProfileTabConfig(
            titleValue: partnerProjectionRequiredText('Eventos'),
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
              titleValue: partnerProjectionRequiredText('Experiências'),
              modules: [
                ProfileModuleConfig(id: ProfileModuleId.experienceCards),
              ],
            ),
            ProfileTabConfig(
              titleValue: partnerProjectionRequiredText('Sobre o Guia'),
              modules: [
                ProfileModuleConfig(
                  id: ProfileModuleId.richText,
                  titleValue: partnerProjectionOptionalText('Quem Somos'),
                ),
              ],
            ),
            ProfileTabConfig(
              titleValue: partnerProjectionRequiredText('Dúvidas'),
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
              titleValue: partnerProjectionRequiredText('Acervo'),
              modules: [
                ProfileModuleConfig(id: ProfileModuleId.videoGallery),
                ProfileModuleConfig(
                  id: ProfileModuleId.richText,
                  titleValue: partnerProjectionOptionalText('Artigos Recentes'),
                ),
              ],
            ),
            ProfileTabConfig(
              titleValue: partnerProjectionRequiredText('Sobre & Apoio'),
              modules: [
                ProfileModuleConfig(
                  id: ProfileModuleId.richText,
                  titleValue: partnerProjectionOptionalText('Sobre'),
                ),
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
              titleValue: partnerProjectionRequiredText('Galeria'),
              modules: [
                ProfileModuleConfig(id: ProfileModuleId.photoGallery),
              ],
            ),
            ProfileTabConfig(
              titleValue: partnerProjectionRequiredText('Recomendações'),
              modules: [
                ProfileModuleConfig(id: ProfileModuleId.affinityCarousels),
              ],
            ),
            ProfileTabConfig(
              titleValue: partnerProjectionRequiredText('Próximos rolês'),
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

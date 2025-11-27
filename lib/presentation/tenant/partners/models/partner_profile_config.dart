import 'package:belluga_now/domain/partners/partner_model.dart';

/// Module identifiers aligned with perfil_other_module.md
enum ProfileModuleId {
  socialScore,
  agendaCarousel,
  agendaList,
  musicPlayer,
  productGrid,
  photoGallery,
  videoGallery,
  experienceCards,
  affinityCarousels,
  supportedEntities,
  richText,
  locationInfo,
  externalLinks,
  faq,
  sponsorBanner,
}

class ProfileModuleConfig {
  ProfileModuleConfig({
    required this.id,
    this.title,
    this.dataKey,
  });

  final ProfileModuleId id;
  final String? title;
  final String? dataKey; // optional key to pick data
}

class PartnerProfileConfig {
  PartnerProfileConfig({
    required this.partner,
    required this.tabs,
  });

  final PartnerModel partner;
  final List<ProfileTabConfig> tabs;
}

class ProfileTabConfig {
  ProfileTabConfig({
    required this.title,
    required this.modules,
  });

  final String title;
  final List<ProfileModuleConfig> modules;
}

import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/domain/partners/account_profile_model.dart';
import 'package:belluga_now/domain/partners/profile_type_registry.dart';
import 'package:belluga_now/domain/partners/projections/partner_profile_config.dart';
import 'package:belluga_now/domain/partners/services/partner_profile_config_builder.dart';
import 'package:belluga_now/domain/repositories/account_profiles_repository_contract.dart';
import 'package:belluga_now/domain/repositories/auth_repository_contract.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value.dart';

enum PartnerFavoriteToggleOutcome {
  toggled,
  requiresAuthentication,
}

class PartnerDetailController implements Disposable {
  PartnerDetailController({
    AccountProfilesRepositoryContract? partnersRepository,
    PartnerProfileConfigBuilder? profileConfigBuilder,
    AuthRepositoryContract? authRepository,
  })  : _partnersRepository = partnersRepository ??
            GetIt.I.get<AccountProfilesRepositoryContract>(),
        _profileConfigBuilder =
            profileConfigBuilder ?? GetIt.I.get<PartnerProfileConfigBuilder>(),
        _authRepository = authRepository ??
            (GetIt.I.isRegistered<AuthRepositoryContract>()
                ? GetIt.I.get<AuthRepositoryContract>()
                : null);

  final AccountProfilesRepositoryContract _partnersRepository;
  final PartnerProfileConfigBuilder _profileConfigBuilder;
  final AuthRepositoryContract? _authRepository;

  final partnerStreamValue = StreamValue<AccountProfileModel?>();
  final isLoadingStreamValue = StreamValue<bool>(defaultValue: false);
  StreamValue<Set<String>> get favoriteIdsStream =>
      _partnersRepository.favoriteAccountProfileIdsStreamValue;
  final profileConfigStreamValue =
      StreamValue<PartnerProfileConfig?>(defaultValue: null);
  final moduleDataStreamValue =
      StreamValue<Map<ProfileModuleId, Object?>>(defaultValue: const {});

  Future<void> loadPartner(String slug) async {
    isLoadingStreamValue.addValue(true);
    try {
      final partner = await _partnersRepository.getAccountProfileBySlug(slug);
      partnerStreamValue.addValue(partner);
      if (partner != null) {
        final capabilities = _resolveRegistry()?.capabilitiesFor(partner.type);
        profileConfigStreamValue.addValue(
          _profileConfigBuilder.build(
            partner,
            capabilities: capabilities,
          ),
        );
        moduleDataStreamValue.addValue(_buildModuleData(partner));
      }
    } finally {
      isLoadingStreamValue.addValue(false);
    }
  }

  PartnerFavoriteToggleOutcome toggleFavorite(String partnerId) {
    if (!_isAuthorized) {
      return PartnerFavoriteToggleOutcome.requiresAuthentication;
    }
    _partnersRepository.toggleFavorite(partnerId);
    return PartnerFavoriteToggleOutcome.toggled;
  }

  bool isFavorite(String partnerId) {
    return _partnersRepository.isFavorite(partnerId);
  }

  bool isFavoritable(AccountProfileModel partner) {
    final registry = _resolveRegistry();
    if (registry == null || registry.isEmpty) return false;
    return registry.isFavoritableFor(partner.type);
  }

  ProfileTypeRegistry? _resolveRegistry() {
    if (!GetIt.I.isRegistered<AppData>()) {
      return null;
    }
    return GetIt.I.get<AppData>().profileTypeRegistry;
  }

  bool get _isAuthorized => _authRepository?.isAuthorized ?? true;

  Map<ProfileModuleId, Object?> _buildModuleData(AccountProfileModel partner) {
    final modules = <ProfileModuleId, Object?>{};
    final bio = partner.bio?.trim();
    if (bio != null && bio.isNotEmpty) {
      modules[ProfileModuleId.richText] = bio;
    }
    return modules;
  }

  @override
  void onDispose() {
    partnerStreamValue.dispose();
    isLoadingStreamValue.dispose();
    profileConfigStreamValue.dispose();
    moduleDataStreamValue.dispose();
  }
}

import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/domain/partners/account_profile_model.dart';
import 'package:belluga_now/domain/partners/profile_type_registry.dart';
import 'package:belluga_now/domain/partners/projections/partner_profile_config.dart';
import 'package:belluga_now/domain/partners/services/partner_profile_config_builder.dart';
import 'package:belluga_now/domain/partners/value_objects/profile_type_key_value.dart';
import 'package:belluga_now/domain/repositories/account_profiles_repository_contract.dart';
import 'package:belluga_now/domain/repositories/auth_repository_contract.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value.dart';

enum AccountProfileFavoriteToggleOutcome {
  toggled,
  requiresAuthentication,
}

class AccountProfileDetailController implements Disposable {
  AccountProfileDetailController({
    AccountProfilesRepositoryContract? accountProfilesRepository,
    PartnerProfileConfigBuilder? profileConfigBuilder,
    AuthRepositoryContract? authRepository,
  })  : _accountProfilesRepository = accountProfilesRepository ??
            GetIt.I.get<AccountProfilesRepositoryContract>(),
        _profileConfigBuilder =
            profileConfigBuilder ?? GetIt.I.get<PartnerProfileConfigBuilder>(),
        _authRepository = authRepository ??
            (GetIt.I.isRegistered<AuthRepositoryContract>()
                ? GetIt.I.get<AuthRepositoryContract>()
                : null);

  final AccountProfilesRepositoryContract _accountProfilesRepository;
  final PartnerProfileConfigBuilder _profileConfigBuilder;
  final AuthRepositoryContract? _authRepository;

  StreamValue<AccountProfileModel?> get accountProfileStreamValue =>
      _accountProfilesRepository.selectedAccountProfileStreamValue;
  final isLoadingStreamValue = StreamValue<bool>(defaultValue: false);
  StreamValue<Set<String>> get favoriteIdsStream =>
      _accountProfilesRepository.favoriteAccountProfileIdsStreamValue;
  final profileConfigStreamValue =
      StreamValue<PartnerProfileConfig?>(defaultValue: null);
  final moduleDataStreamValue =
      StreamValue<Map<ProfileModuleId, Object?>>(defaultValue: const {});

  Future<void> loadAccountProfile(String slug) async {
    isLoadingStreamValue.addValue(true);
    try {
      await _accountProfilesRepository.loadAccountProfileBySlug(slug);
      final accountProfile =
          _accountProfilesRepository.selectedAccountProfileStreamValue.value;
      if (accountProfile == null) {
        profileConfigStreamValue.addValue(null);
        moduleDataStreamValue.addValue(const {});
        return;
      }
      loadResolvedAccountProfile(accountProfile);
    } finally {
      isLoadingStreamValue.addValue(false);
    }
  }

  void loadResolvedAccountProfile(AccountProfileModel accountProfile) {
    accountProfileStreamValue.addValue(accountProfile);
    final capabilities =
        _resolveRegistry()?.capabilitiesFor(ProfileTypeKeyValue(accountProfile.type));
    profileConfigStreamValue.addValue(
      _profileConfigBuilder.build(
        accountProfile,
        capabilities: capabilities,
      ),
    );
    moduleDataStreamValue.addValue(_buildModuleData(accountProfile));
  }

  AccountProfileFavoriteToggleOutcome toggleFavorite(String accountProfileId) {
    if (!_isAuthorized) {
      return AccountProfileFavoriteToggleOutcome.requiresAuthentication;
    }
    _accountProfilesRepository.toggleFavorite(accountProfileId);
    return AccountProfileFavoriteToggleOutcome.toggled;
  }

  bool isFavorite(String accountProfileId) {
    return _accountProfilesRepository.isFavorite(accountProfileId);
  }

  bool isFavoritable(AccountProfileModel accountProfile) {
    final registry = _resolveRegistry();
    if (registry == null || registry.isEmpty) return false;
    return registry.isFavoritableFor(ProfileTypeKeyValue(accountProfile.type));
  }

  ProfileTypeRegistry? _resolveRegistry() {
    if (!GetIt.I.isRegistered<AppData>()) {
      return null;
    }
    return GetIt.I.get<AppData>().profileTypeRegistry;
  }

  bool get _isAuthorized => _authRepository?.isAuthorized ?? true;

  Map<ProfileModuleId, Object?> _buildModuleData(
    AccountProfileModel accountProfile,
  ) {
    final modules = <ProfileModuleId, Object?>{};
    final bio = accountProfile.bio?.trim();
    if (bio != null && bio.isNotEmpty) {
      modules[ProfileModuleId.richText] = bio;
    }
    return modules;
  }

  @override
  void onDispose() {
    isLoadingStreamValue.dispose();
    profileConfigStreamValue.dispose();
    moduleDataStreamValue.dispose();
  }
}

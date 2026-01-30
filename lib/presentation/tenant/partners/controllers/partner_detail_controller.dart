import 'package:belluga_now/domain/partners/account_profile_model.dart';
import 'package:belluga_now/domain/partners/profile_type_registry.dart';
import 'package:belluga_now/domain/repositories/account_profiles_repository_contract.dart';
import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/infrastructure/dal/datasources/mock_partner_profile_database.dart';
import 'package:belluga_now/infrastructure/dal/datasources/mock_partner_content_repository.dart';
import 'package:belluga_now/presentation/tenant/partners/models/partner_profile_config.dart';
import 'package:belluga_now/infrastructure/services/mock_audio_player_service.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value.dart';

class PartnerDetailController implements Disposable {
  PartnerDetailController({
    AccountProfilesRepositoryContract? partnersRepository,
    MockPartnerProfileDatabase? profileDatabase,
    MockPartnerContentRepository? contentRepository,
    MockAudioPlayerService? audioPlayerService,
  })  : _partnersRepository =
            partnersRepository ?? GetIt.I.get<AccountProfilesRepositoryContract>(),
        _profileDatabase = profileDatabase ?? MockPartnerProfileDatabase(),
        _contentRepository = contentRepository ?? MockPartnerContentRepository(),
        _audioPlayerService = audioPlayerService ??
            (GetIt.I.isRegistered<MockAudioPlayerService>()
                ? GetIt.I.get<MockAudioPlayerService>()
                : GetIt.I.registerSingleton<MockAudioPlayerService>(
                    MockAudioPlayerService()));

  final AccountProfilesRepositoryContract _partnersRepository;
  final MockPartnerProfileDatabase _profileDatabase;
  final MockPartnerContentRepository _contentRepository;
  final MockAudioPlayerService _audioPlayerService;

  final partnerStreamValue = StreamValue<AccountProfileModel?>();
  final isLoadingStreamValue = StreamValue<bool>(defaultValue: false);
  StreamValue<Set<String>> get favoriteIdsStream =>
      _partnersRepository.favoriteAccountProfileIdsStreamValue;
  final profileConfigStreamValue =
      StreamValue<PartnerProfileConfig?>(defaultValue: null);
  final moduleDataStreamValue =
      StreamValue<Map<ProfileModuleId, dynamic>>(defaultValue: const {});
  MockAudioPlayerService get audioPlayerService => _audioPlayerService;

  Future<void> loadPartner(String slug) async {
    isLoadingStreamValue.addValue(true);
    try {
      final partner = await _partnersRepository.getAccountProfileBySlug(slug);
      partnerStreamValue.addValue(partner);
      if (partner != null) {
        profileConfigStreamValue
            .addValue(_profileDatabase.buildConfig(partner));
        moduleDataStreamValue.addValue(
          _contentRepository.loadModulesForPartner(partner),
        );
      }
    } finally {
      isLoadingStreamValue.addValue(false);
    }
  }

  void toggleFavorite(String partnerId) {
    _partnersRepository.toggleFavorite(partnerId);
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

  @override
  void onDispose() {
    partnerStreamValue.dispose();
    isLoadingStreamValue.dispose();
    profileConfigStreamValue.dispose();
    moduleDataStreamValue.dispose();
  }
}

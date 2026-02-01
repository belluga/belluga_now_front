import 'dart:async';

import 'package:belluga_now/domain/media/audio_player_service_contract.dart';
import 'package:belluga_now/domain/partners/account_profile_model.dart';
import 'package:belluga_now/domain/partners/projections/partner_profile_config.dart';
import 'package:belluga_now/domain/partners/projections/partner_profile_module_data.dart';
import 'package:belluga_now/domain/partners/profile_type_registry.dart';
import 'package:belluga_now/domain/partners/services/partner_profile_config_builder.dart';
import 'package:belluga_now/domain/repositories/account_profiles_repository_contract.dart';
import 'package:belluga_now/domain/repositories/partner_profile_content_repository_contract.dart';
import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value.dart';

class PartnerDetailController implements Disposable {
  PartnerDetailController({
    AccountProfilesRepositoryContract? partnersRepository,
    PartnerProfileConfigBuilder? profileConfigBuilder,
    PartnerProfileContentRepositoryContract? contentRepository,
    AudioPlayerServiceContract? audioPlayerService,
  })  : _partnersRepository =
            partnersRepository ?? GetIt.I.get<AccountProfilesRepositoryContract>(),
        _profileConfigBuilder =
            profileConfigBuilder ?? GetIt.I.get<PartnerProfileConfigBuilder>(),
        _contentRepository =
            contentRepository ?? GetIt.I.get<PartnerProfileContentRepositoryContract>(),
        _audioPlayerService =
            audioPlayerService ?? GetIt.I.get<AudioPlayerServiceContract>();

  final AccountProfilesRepositoryContract _partnersRepository;
  final PartnerProfileConfigBuilder _profileConfigBuilder;
  final PartnerProfileContentRepositoryContract _contentRepository;
  final AudioPlayerServiceContract _audioPlayerService;
  StreamSubscription<PartnerMediaView?>? _audioSubscription;

  final partnerStreamValue = StreamValue<AccountProfileModel?>();
  final isLoadingStreamValue = StreamValue<bool>(defaultValue: false);
  StreamValue<Set<String>> get favoriteIdsStream =>
      _partnersRepository.favoriteAccountProfileIdsStreamValue;
  final profileConfigStreamValue =
      StreamValue<PartnerProfileConfig?>(defaultValue: null);
  final moduleDataStreamValue =
      StreamValue<Map<ProfileModuleId, Object?>>(defaultValue: const {});
  final currentTrackStreamValue = StreamValue<PartnerMediaView?>();

  StreamValue<bool> get isPlayingStreamValue =>
      _audioPlayerService.isPlayingStream;

  void playTrack(PartnerMediaView track) {
    _audioPlayerService.play(track);
  }

  void togglePlayback() {
    _audioPlayerService.toggle();
  }

  Future<void> loadPartner(String slug) async {
    _attachAudioListener();
    isLoadingStreamValue.addValue(true);
    try {
      final partner = await _partnersRepository.getAccountProfileBySlug(slug);
      partnerStreamValue.addValue(partner);
      if (partner != null) {
        final capabilities =
            _resolveRegistry()?.capabilitiesFor(partner.type);
        profileConfigStreamValue.addValue(
          _profileConfigBuilder.build(
            partner,
            capabilities: capabilities,
          ),
        );
        final rawModules = _contentRepository.loadModulesForPartner(partner);
        moduleDataStreamValue.addValue(rawModules);
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

  void _attachAudioListener() {
    _audioSubscription ??=
        _audioPlayerService.currentTrackStream.stream.listen((track) {
      currentTrackStreamValue.addValue(track);
    });
  }

  @override
  void onDispose() {
    partnerStreamValue.dispose();
    isLoadingStreamValue.dispose();
    profileConfigStreamValue.dispose();
    moduleDataStreamValue.dispose();
    currentTrackStreamValue.dispose();
    _audioSubscription?.cancel();
  }
}

import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/domain/partners/account_profile_model.dart';
import 'package:belluga_now/domain/partners/profile_type_registry.dart';
import 'package:belluga_now/domain/partners/projections/partner_profile_config.dart';
import 'package:belluga_now/domain/partners/projections/partner_profile_module_data.dart';
import 'package:belluga_now/domain/partners/projections/value_objects/partner_projection_text_values.dart';
import 'package:belluga_now/domain/partners/services/partner_profile_config_builder.dart';
import 'package:belluga_now/domain/partners/value_objects/profile_type_key_value.dart';
import 'package:belluga_now/domain/repositories/account_profiles_repository_contract.dart';
import 'package:belluga_now/domain/repositories/auth_repository_contract.dart';
import 'package:belluga_now/domain/repositories/invites_repository_contract.dart';
import 'package:belluga_now/domain/repositories/user_events_repository_contract.dart';
import 'package:belluga_now/domain/repositories/value_objects/user_events_repository_contract_values.dart';
import 'package:belluga_now/presentation/shared/visuals/account_profile_visual_resolver.dart';
import 'package:belluga_now/presentation/shared/visuals/resolved_account_profile_visual.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value.dart';
import 'dart:async';

enum AccountProfileFavoriteToggleOutcome {
  toggled,
  requiresAuthentication,
}

class AccountProfileDetailController implements Disposable {
  AccountProfileDetailController({
    AccountProfilesRepositoryContract? accountProfilesRepository,
    PartnerProfileConfigBuilder? profileConfigBuilder,
    AuthRepositoryContract? authRepository,
    UserEventsRepositoryContract? userEventsRepository,
    InvitesRepositoryContract? invitesRepository,
  })  : _accountProfilesRepository = accountProfilesRepository ??
            GetIt.I.get<AccountProfilesRepositoryContract>(),
        _profileConfigBuilder = profileConfigBuilder ??
            (GetIt.I.isRegistered<PartnerProfileConfigBuilder>()
                ? GetIt.I.get<PartnerProfileConfigBuilder>()
                : PartnerProfileConfigBuilder()),
        _authRepository = authRepository ??
            (GetIt.I.isRegistered<AuthRepositoryContract>()
                ? GetIt.I.get<AuthRepositoryContract>()
                : null),
        _userEventsRepository = userEventsRepository ??
            (GetIt.I.isRegistered<UserEventsRepositoryContract>()
                ? GetIt.I.get<UserEventsRepositoryContract>()
                : null),
        _invitesRepository = invitesRepository ??
            (GetIt.I.isRegistered<InvitesRepositoryContract>()
                ? GetIt.I.get<InvitesRepositoryContract>()
                : null) {
    _favoriteIdsSubscription = _accountProfilesRepository
        .favoriteAccountProfileIdsStreamValue.stream
        .listen(
      (ids) {
        favoriteIdsStreamValue.addValue(
          ids.map((entry) => entry.value).toSet(),
        );
      },
    );
    favoriteIdsStreamValue.addValue(
      _accountProfilesRepository.favoriteAccountProfileIdsStreamValue.value
          .map((entry) => entry.value)
          .toSet(),
    );
    _confirmedEventIdsSubscription =
        _userEventsRepository?.confirmedEventIdsStream.stream.listen((_) {
      _bumpAgendaStatusRevision();
    });
    _pendingInvitesSubscription =
        _invitesRepository?.pendingInvitesStreamValue.stream.listen((_) {
      _bumpAgendaStatusRevision();
    });
  }

  final AccountProfilesRepositoryContract _accountProfilesRepository;
  final PartnerProfileConfigBuilder _profileConfigBuilder;
  final AuthRepositoryContract? _authRepository;
  final UserEventsRepositoryContract? _userEventsRepository;
  final InvitesRepositoryContract? _invitesRepository;
  StreamSubscription<Set<AccountProfilesRepositoryContractPrimString>>?
      _favoriteIdsSubscription;
  StreamSubscription<Set<UserEventsRepositoryContractPrimString>>?
      _confirmedEventIdsSubscription;
  StreamSubscription<dynamic>? _pendingInvitesSubscription;

  StreamValue<AccountProfileModel?> get accountProfileStreamValue =>
      _accountProfilesRepository.selectedAccountProfileStreamValue;
  final isLoadingStreamValue = StreamValue<bool>(defaultValue: false);
  final favoriteIdsStreamValue =
      StreamValue<Set<String>>(defaultValue: const {});
  StreamValue<Set<String>> get favoriteIdsStream => favoriteIdsStreamValue;
  final agendaStatusRevisionStreamValue = StreamValue<int>(defaultValue: 0);
  final errorMessageStreamValue = StreamValue<String>(defaultValue: '');
  final profileConfigStreamValue =
      StreamValue<PartnerProfileConfig?>(defaultValue: null);
  final moduleDataStreamValue =
      StreamValue<Map<ProfileModuleId, Object?>>(defaultValue: const {});

  Future<void> loadAccountProfile(String slug) async {
    isLoadingStreamValue.addValue(true);
    errorMessageStreamValue.addValue('');
    try {
      await _accountProfilesRepository.loadAccountProfileBySlug(
        AccountProfilesRepositoryContractPrimString.fromRaw(slug),
      );
      final accountProfile =
          _accountProfilesRepository.selectedAccountProfileStreamValue.value;
      if (accountProfile == null) {
        _accountProfilesRepository.clearSelectedAccountProfile();
        profileConfigStreamValue.addValue(null);
        moduleDataStreamValue.addValue(const {});
        return;
      }
      await loadResolvedAccountProfile(accountProfile);
    } catch (error) {
      errorMessageStreamValue.addValue(
        'Falha ao preparar o perfil',
      );
    } finally {
      isLoadingStreamValue.addValue(false);
    }
  }

  Future<void> loadResolvedAccountProfile(
      AccountProfileModel accountProfile) async {
    errorMessageStreamValue.addValue('');
    _accountProfilesRepository.setSelectedAccountProfile(accountProfile);
    final capabilities = _resolveRegistry()
        ?.capabilitiesFor(ProfileTypeKeyValue(accountProfile.type));
    profileConfigStreamValue.addValue(
      _profileConfigBuilder.build(
        accountProfile,
        capabilities: capabilities,
      ),
    );
    try {
      moduleDataStreamValue.addValue(await _buildModuleData(accountProfile));
    } catch (_) {
      errorMessageStreamValue.addValue('Falha ao preparar o perfil');
      moduleDataStreamValue.addValue(const {});
    }
  }

  AccountProfileFavoriteToggleOutcome toggleFavorite(String accountProfileId) {
    if (!_isAuthorized) {
      return AccountProfileFavoriteToggleOutcome.requiresAuthentication;
    }
    _accountProfilesRepository.toggleFavorite(
      AccountProfilesRepositoryContractPrimString.fromRaw(accountProfileId),
    );
    return AccountProfileFavoriteToggleOutcome.toggled;
  }

  bool isFavorite(String accountProfileId) {
    return _accountProfilesRepository
        .isFavorite(
          AccountProfilesRepositoryContractPrimString.fromRaw(accountProfileId),
        )
        .value;
  }

  bool isFavoritable(AccountProfileModel accountProfile) {
    final registry = _resolveRegistry();
    if (registry == null || registry.isEmpty) return false;
    return registry.isFavoritableFor(ProfileTypeKeyValue(accountProfile.type));
  }

  ResolvedAccountProfileVisual resolvedVisualFor(
    AccountProfileModel accountProfile,
  ) {
    return AccountProfileVisualResolver.resolve(
      accountProfile: accountProfile,
      registry: _resolveRegistry(),
    );
  }

  String typeLabelFor(AccountProfileModel accountProfile) {
    return resolvedVisualFor(accountProfile).typeLabel;
  }

  ProfileTypeRegistry? _resolveRegistry() {
    if (!GetIt.I.isRegistered<AppData>()) {
      return null;
    }
    return GetIt.I.get<AppData>().profileTypeRegistry;
  }

  bool get _isAuthorized => _authRepository?.isAuthorized ?? true;

  void _bumpAgendaStatusRevision() {
    agendaStatusRevisionStreamValue.addValue(
      agendaStatusRevisionStreamValue.value + 1,
    );
  }

  bool isEventConfirmed(String eventId) {
    final repository = _userEventsRepository;
    if (repository == null) {
      return false;
    }
    return repository
        .isEventConfirmed(
          userEventsRepoString(
            eventId,
            defaultValue: '',
            isRequired: true,
          ),
        )
        .value;
  }

  int pendingInviteCount(String eventId) {
    final repository = _invitesRepository;
    if (repository == null) {
      return 0;
    }
    return repository.pendingInvitesStreamValue.value
        .where((invite) => invite.eventId == eventId)
        .length;
  }

  String? distanceLabelFor(
    AccountProfileModel accountProfile,
    PartnerEventView event,
  ) {
    final distanceMeters = accountProfile.distanceMeters;
    final venueId = event.venueId;
    if (distanceMeters == null ||
        venueId == null ||
        venueId != accountProfile.id) {
      return null;
    }
    if (distanceMeters < 1000) {
      return '${distanceMeters.round()} m';
    }
    return '${(distanceMeters / 1000).toStringAsFixed(1)} km';
  }

  Future<Map<ProfileModuleId, Object?>> _buildModuleData(
    AccountProfileModel accountProfile,
  ) async {
    final modules = <ProfileModuleId, Object?>{};
    final bio = accountProfile.bio?.trim();
    if (bio != null && bio.isNotEmpty) {
      modules[ProfileModuleId.richText] = bio;
    }
    final location = _buildLocationModuleData(accountProfile);
    if (location != null) {
      modules[ProfileModuleId.locationInfo] = location;
    }
    final agenda = _buildAgendaModuleData(accountProfile);
    if (agenda.isNotEmpty) {
      modules[ProfileModuleId.agendaList] = agenda;
    }
    return modules;
  }

  PartnerLocationView? _buildLocationModuleData(
    AccountProfileModel accountProfile,
  ) {
    final lat = accountProfile.locationLat;
    final lng = accountProfile.locationLng;
    final address = accountProfile.locationAddress?.trim();
    final hasCoordinates = lat != null && lng != null;
    final hasAddress = address != null && address.isNotEmpty;
    if (!hasCoordinates && !hasAddress) {
      return null;
    }

    return PartnerLocationView(
      addressValue: partnerProjectionRequiredText(address ?? ''),
      statusValue: partnerProjectionRequiredText('location_available'),
      latValue:
          hasCoordinates ? partnerProjectionOptionalText(lat.toString()) : null,
      lngValue:
          hasCoordinates ? partnerProjectionOptionalText(lng.toString()) : null,
    );
  }

  List<PartnerEventView> _buildAgendaModuleData(
    AccountProfileModel accountProfile,
  ) {
    return accountProfile.agendaEvents;
  }

  @override
  void onDispose() {
    _favoriteIdsSubscription?.cancel();
    _confirmedEventIdsSubscription?.cancel();
    _pendingInvitesSubscription?.cancel();
    _accountProfilesRepository.clearSelectedAccountProfile();
    errorMessageStreamValue.dispose();
    favoriteIdsStreamValue.dispose();
    agendaStatusRevisionStreamValue.dispose();
    isLoadingStreamValue.dispose();
    profileConfigStreamValue.dispose();
    moduleDataStreamValue.dispose();
  }
}

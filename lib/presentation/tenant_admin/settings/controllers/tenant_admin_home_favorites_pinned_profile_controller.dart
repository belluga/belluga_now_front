import 'package:belluga_now/application/tenant_admin/tenant_admin_account_profile_candidate_discovery_page_loader.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_account_profiles_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_account_profile_candidates_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_settings_repository_contract.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile_candidate.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_home_favorites_pinned_profile_settings.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_account_profile_id_value.dart';
import 'package:belluga_now/presentation/tenant_admin/account_profiles/controllers/tenant_admin_account_profile_candidate_picker_controller.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value.dart';

class TenantAdminHomeFavoritesPinnedProfileController implements Disposable {
  TenantAdminHomeFavoritesPinnedProfileController({
    TenantAdminSettingsRepositoryContract? settingsRepository,
    TenantAdminAccountProfileCandidatesRepositoryContract? candidatesRepository,
  }) : _settingsRepository =
           settingsRepository ??
           GetIt.I.get<TenantAdminSettingsRepositoryContract>(),
       _candidatesRepository =
           candidatesRepository ??
           GetIt.I.get<TenantAdminAccountProfilesRepositoryContract>();

  final TenantAdminSettingsRepositoryContract _settingsRepository;
  final TenantAdminAccountProfileCandidatesRepositoryContract
  _candidatesRepository;

  final settingsStreamValue =
      StreamValue<TenantAdminHomeFavoritesPinnedProfileSettings?>();
  final isLoadingStreamValue = StreamValue<bool>(defaultValue: false);
  final isSavingStreamValue = StreamValue<bool>(defaultValue: false);
  final errorStreamValue = StreamValue<String?>();
  String? _draftAccountProfileId;
  String? _draftDisplayName;
  bool _isDisposed = false;

  String? get draftAccountProfileId => _draftAccountProfileId;
  String? get draftDisplayName => _draftDisplayName;
  bool get hasAuthoritativeBaseline => settingsStreamValue.value != null;

  Future<void> init() async {
    if (_isDisposed) return;
    isLoadingStreamValue.addValue(true);
    try {
      final value = await _settingsRepository.fetchHomeFavoritesPinnedProfile();
      if (_isDisposed) return;
      _apply(value);
      errorStreamValue.addValue(null);
    } catch (error) {
      if (_isDisposed) return;
      errorStreamValue.addValue(error.toString());
    } finally {
      if (!_isDisposed) isLoadingStreamValue.addValue(false);
    }
  }

  TenantAdminAccountProfileCandidatePickerController createPickerSession() {
    return TenantAdminAccountProfileCandidatePickerController(
      pageLoader: TenantAdminAccountProfileCandidateDiscoveryPageLoader(
        repository: _candidatesRepository,
      ),
      scope: TenantAdminAccountProfileCandidateScope.homeFavoritesPinnedProfile,
      maxSelections: 1,
    );
  }

  void disposePickerSession(
    TenantAdminAccountProfileCandidatePickerController session,
  ) => session.dispose();

  void select(TenantAdminAccountProfileSelectionSummary profile) {
    if (_isDisposed) return;
    _draftAccountProfileId = profile.id;
    _draftDisplayName = profile.displayName;
    settingsStreamValue.addValue(settingsStreamValue.value);
  }

  void clear() {
    if (_isDisposed) return;
    _draftAccountProfileId = null;
    _draftDisplayName = null;
    settingsStreamValue.addValue(settingsStreamValue.value);
  }

  Future<bool> save() async {
    if (_isDisposed ||
        isLoadingStreamValue.value ||
        !hasAuthoritativeBaseline) {
      return false;
    }
    isSavingStreamValue.addValue(true);
    try {
      final value = await _settingsRepository.updateHomeFavoritesPinnedProfile(
        accountProfileId: _draftAccountProfileId == null
            ? null
            : TenantAdminAccountProfileIdValue(_draftAccountProfileId!),
      );
      if (_isDisposed) return false;
      _apply(value);
      errorStreamValue.addValue(null);
      return true;
    } catch (error) {
      if (_isDisposed) return false;
      errorStreamValue.addValue(error.toString());
      return false;
    } finally {
      if (!_isDisposed) isSavingStreamValue.addValue(false);
    }
  }

  void _apply(TenantAdminHomeFavoritesPinnedProfileSettings value) {
    _draftAccountProfileId = value.accountProfileId;
    _draftDisplayName = value.selectedProfileDisplayName;
    settingsStreamValue.addValue(value);
  }

  @override
  void onDispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    settingsStreamValue.dispose();
    isLoadingStreamValue.dispose();
    isSavingStreamValue.dispose();
    errorStreamValue.dispose();
  }
}
